#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Starting Pulse Docker Agent add-on"

# -----------------------------------------------------------------------------
# Read configuration from /data/options.json
# -----------------------------------------------------------------------------
PULSE_URL="$(bashio::config 'pulse_url')"
API_TOKEN="$(bashio::config 'api_token')"
INTERVAL="$(bashio::config 'interval')"
LOG_LEVEL="$(bashio::config 'log_level')"
AGENT_VERSION="$(bashio::config 'agent_version')"
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

# agent_version MUST come from config tab
if bashio::config.is_empty 'agent_version'; then
    bashio::log.error "agent_version is required but not set in add-on options."
    bashio::log.error "Please set it in the add-on configuration (e.g. 4.36.1)."
    exit 1
fi

bashio::log.info "Using Pulse URL: ${PULSE_URL}"
bashio::log.info "Using agent version: ${AGENT_VERSION}"
bashio::log.info "Reporting interval: ${INTERVAL}"
bashio::log.info "Log level: ${LOG_LEVEL}"
[ -n "${EXTRA_TARGETS}" ] && bashio::log.info "Extra targets: ${EXTRA_TARGETS}"

# -----------------------------------------------------------------------------
# Determine architecture for download (amd64 / arm64)
# -----------------------------------------------------------------------------
ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        ARCH="amd64"
        bashio::log.warning "Unknown arch '${ARCH_RAW}', defaulting to amd64"
        ;;
esac

# -----------------------------------------------------------------------------
# Download / update pulse-docker-agent binary if needed
# -----------------------------------------------------------------------------
AGENT_BIN="/usr/local/bin/pulse-docker-agent"
VERSION_FILE="/data/agent_version"

NEED_DOWNLOAD=false
if [ ! -x "${AGENT_BIN}" ]; then
    bashio::log.info "Agent binary not found, will download."
    NEED_DOWNLOAD=true
elif [ "$(cat "${VERSION_FILE}" 2>/dev/null || echo '')" != "${AGENT_VERSION}" ]; then
    bashio::log.info "Agent version changed, will re-download."
    NEED_DOWNLOAD=true
fi

if [ "${NEED_DOWNLOAD}" = true ]; then
    # Normalise to tag format: vX.Y.Z even if user entered X.Y.Z
    TAG="${AGENT_VERSION}"
    case "${TAG}" in
        v*) ;;           # already has v prefix
        *)  TAG="v${TAG}" ;;
    esac

    DOWNLOAD_URL="https://github.com/rcourtman/Pulse/releases/download/${TAG}/pulse-${TAG}-linux-${ARCH}.tar.gz"
    TMP_TAR="/tmp/pulse-agent.tar.gz"
    TMP_DIR="/tmp/pulse-agent"

    bashio::log.info "Downloading Pulse Docker Agent from: ${DOWNLOAD_URL}"
    if ! curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_TAR}"; then
        bashio::log.error "Failed to download agent from ${DOWNLOAD_URL}"
        exit 1
    fi

    rm -rf "${TMP_DIR}"
    mkdir -p "${TMP_DIR}"
    tar -xzf "${TMP_TAR}" -C "${TMP_DIR}"

    # Normal layout is bin/pulse-docker-agent inside the tarball
    if [ -f "${TMP_DIR}/bin/pulse-docker-agent" ]; then
        AGENT_SOURCE="${TMP_DIR}/bin/pulse-docker-agent"
    else
        # Fallback: search just in case layout changes
        AGENT_SOURCE="$(find "${TMP_DIR}" -name 'pulse-docker-agent' | head -n 1 || true)"
    fi

    if [ -z "${AGENT_SOURCE}" ] || [ ! -f "${AGENT_SOURCE}" ]; then
        bashio::log.error "Agent binary not found in archive."
        exit 1
    fi

    install -m 0755 "${AGENT_SOURCE}" "${AGENT_BIN}"
    echo "${AGENT_VERSION}" > "${VERSION_FILE}"

    rm -rf "${TMP_TAR}" "${TMP_DIR}"
    bashio::log.info "Installed pulse-docker-agent ${AGENT_VERSION} to ${AGENT_BIN}"
else
    bashio::log.info "Existing agent binary and version match; no download needed."
fi

# -----------------------------------------------------------------------------
# Export environment variables expected by pulse-docker-agent
# -----------------------------------------------------------------------------
export PULSE_URL="${PULSE_URL}"
export PULSE_TOKEN="${API_TOKEN}"

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
bashio::log.info "Starting pulse-docker-agent with interval ${INTERVAL}"
exec "${AGENT_BIN}" --interval "${INTERVAL}"
