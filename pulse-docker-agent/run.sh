#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Starting Pulse Unified Agent add-on"

# -----------------------------------------------------------------------------
# Read configuration from /data/options.json
# -----------------------------------------------------------------------------
PULSE_URL="$(bashio::config 'pulse_url')"
API_TOKEN="$(bashio::config 'api_token')"
INTERVAL="$(bashio::config 'interval')"
LOG_LEVEL="$(bashio::config 'log_level')"
if bashio::config.has_value 'agent_version'; then
    AGENT_VERSION="$(bashio::config 'agent_version')"
else
    AGENT_VERSION=""
fi
EXTRA_TARGETS="$(bashio::config 'extra_targets')"

if bashio::config.is_empty 'pulse_url'; then
    bashio::log.error "pulse_url is required but not set in add-on options."
    exit 1
fi

if bashio::config.is_empty 'api_token'; then
    bashio::log.error "api_token is required but not set in add-on options."
    exit 1
fi

if bashio::config.is_empty 'interval'; then
    INTERVAL="30s"
    bashio::log.warning "interval not set, defaulting to ${INTERVAL}"
fi


bashio::log.info "Using Pulse URL: ${PULSE_URL}"
bashio::log.info "Reporting interval: ${INTERVAL}"
bashio::log.info "Log level: ${LOG_LEVEL}"
[ -n "${EXTRA_TARGETS}" ] && bashio::log.info "Extra targets: ${EXTRA_TARGETS}"

# -----------------------------------------------------------------------------
# Determine architecture for download (amd64 / arm64)
# -----------------------------------------------------------------------------
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
    x86_64)          ARCH="amd64" ;;
    aarch64|arm64)   ARCH="arm64" ;;
    *)               ARCH="amd64" ;;
esac

# -----------------------------------------------------------------------------
# Download / update pulse-agent binary if needed
# -----------------------------------------------------------------------------
AGENT_BIN="/usr/local/bin/pulse-agent"

# If agent_version is set, we use GitHub (legacy behavior or specific version pinned)
# If not set, we use the Pulse server to get the latest
if [ -n "${AGENT_VERSION}" ]; then
    VERSION_FILE="/data/agent_version"
    NEED_DOWNLOAD=false
    if [ ! -x "${AGENT_BIN}" ]; then
        bashio::log.info "Agent binary not found, will download version ${AGENT_VERSION} from GitHub."
        NEED_DOWNLOAD=true
    elif [ "$(cat "${VERSION_FILE}" 2>/dev/null || echo '')" != "${AGENT_VERSION}" ]; then
        bashio::log.info "Agent version changed to ${AGENT_VERSION}, will re-download from GitHub."
        NEED_DOWNLOAD=true
    fi

    if [ "${NEED_DOWNLOAD}" = true ]; then
        TAG="${AGENT_VERSION}"
        case "${TAG}" in
            v*) ;;
            *)  TAG="v${TAG}" ;;
        esac

        DOWNLOAD_URL="https://github.com/rcourtman/Pulse/releases/download/${TAG}/pulse-agent-${TAG}-linux-${ARCH}.tar.gz"
        TMP_TAR="/tmp/pulse-agent.tar.gz"
        TMP_DIR="/tmp/pulse-agent"

        bashio::log.info "Downloading Pulse Unified Agent from GitHub: ${DOWNLOAD_URL}"
        if ! curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_TAR}"; then
            bashio::log.error "Failed to download agent from ${DOWNLOAD_URL}"
            exit 1
        fi

        rm -rf "${TMP_DIR}"
        mkdir -p "${TMP_DIR}"
        tar -xzf "${TMP_TAR}" -C "${TMP_DIR}"

        if [ -f "${TMP_DIR}/bin/pulse-agent" ]; then
            AGENT_SOURCE="${TMP_DIR}/bin/pulse-agent"
        else
            AGENT_SOURCE="$(find "${TMP_DIR}" -name 'pulse-agent' | head -n 1 || true)"
        fi

        if [ -z "${AGENT_SOURCE}" ] || [ ! -f "${AGENT_SOURCE}" ]; then
            bashio::log.error "Agent binary not found in archive."
            exit 1
        fi

        install -m 0755 "${AGENT_SOURCE}" "${AGENT_BIN}"
        echo "${AGENT_VERSION}" > "${VERSION_FILE}"
        rm -rf "${TMP_TAR}" "${TMP_DIR}"
        bashio::log.info "Installed pulse-agent ${AGENT_VERSION} from GitHub."
    fi
else
    # Always try to download the latest binary from the Pulse server if not present
    # The agent itself will handle auto-updates once running
    if [ ! -x "${AGENT_BIN}" ]; then
        bashio::log.info "Agent binary not found, downloading latest from Pulse server..."
        
        # Pulse server provides binaries at /download/pulse-agent-linux-<arch>
        DOWNLOAD_URL="${PULSE_URL}/download/pulse-agent-linux-${ARCH}"
        
        bashio::log.info "Downloading from: ${DOWNLOAD_URL}"
        if ! curl -fsSL "${DOWNLOAD_URL}" -o "${AGENT_BIN}"; then
            bashio::log.error "Failed to download agent from ${DOWNLOAD_URL}"
            bashio::log.error "Please ensure the Pulse server is reachable and the URL is correct."
            exit 1
        fi
        chmod +x "${AGENT_BIN}"
        bashio::log.info "Successfully installed pulse-agent from Pulse server."
    fi
fi

# -----------------------------------------------------------------------------
# Export environment variables expected by pulse-agent
# -----------------------------------------------------------------------------
export PULSE_URL="${PULSE_URL}"
export PULSE_TOKEN="${API_TOKEN}"
export PULSE_ENABLE_DOCKER="true"
# Auto-update is enabled by default in the agent, but we can be explicit
export PULSE_DISABLE_AUTO_UPDATE="false"

# Optional multi-target string, e.g. "http://pulse1:7655|TOKEN1,http://pulse2:7655|TOKEN2"
if [ -n "${EXTRA_TARGETS}" ]; then
    export PULSE_TARGETS="${EXTRA_TARGETS}"
fi

if [ -n "${LOG_LEVEL}" ]; then
    export LOG_LEVEL="${LOG_LEVEL}"
fi

# -----------------------------------------------------------------------------
# Start the agent in the foreground
# -----------------------------------------------------------------------------
bashio::log.info "Starting pulse-agent with interval ${INTERVAL}"
exec "${AGENT_BIN}" --interval "${INTERVAL}"
