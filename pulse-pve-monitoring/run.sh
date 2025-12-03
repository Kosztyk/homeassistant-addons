#!/usr/bin/env bash
set -e

# Home Assistant add-on style logging
log() {
  echo "[INFO] $*"
}

log "Starting Pulse PVE Monitoring add-on"

# Ensure data dir exists
mkdir -p /data

# HA options are injected as environment variables (like LOG_LEVEL, etc.)
# You can adapt these if Pulse supports them.
if [[ -n "${LOG_LEVEL}" ]]; then
  log "Log level set to: ${LOG_LEVEL}"
fi

log "Using data directory: /data"

# If the upstream image uses an ENTRYPOINT/CMD to start Pulse, we should
# call that directly. For many images, the default CMD might be something like:
#   ["pulse", "server"]
# or a shell script. Since we don't know exactly, the safest generic way is to
# exec the original command if we know it. If not, we assume "pulse" starts it.

# Try to run pulse binary if present
if command -v pulse >/dev/null 2>&1; then
  log "Found 'pulse' binary, starting Pulse..."
  exec pulse
else
  log "No 'pulse' binary found. Attempting to run default command..."
  # Fallback: try to run the default CMD from the original image if we know it.
  # If rcourtman/pulse:latest uses a script like /entrypoint.sh we can do:
  if [[ -x /entrypoint.sh ]]; then
    exec /entrypoint.sh
  else
    log "ERROR: Could not determine how to start Pulse inside the container."
    sleep 300
  fi
fi
