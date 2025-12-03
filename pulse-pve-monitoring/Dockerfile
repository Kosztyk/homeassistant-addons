ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM ${BUILD_FROM}

# Environment for Home Assistant add-ons
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install any tools you might want (curl, etc.)
RUN apk add --no-cache curl jq

# Pull in the Pulse image filesystem via multi-stage, or run it directly.
# Easiest: use the Pulse image as a base instead of HA base.
# If you prefer to stick with HA base images, you need to manually install Pulse.
# For simplicity and closest behavior to your docker run, let's just base directly on Pulse.

# --- SIMPLER OPTION: base directly on Pulse image instead of HA base ---
# Comment the previous FROM and use this instead if you want 1:1 behavior:
# FROM rcourtman/pulse:latest

# If you use rcourtman/pulse:latest as base:
#   - It already exposes the app on 7655 and uses /data
#   - We only need s6-overlay entrypoint for HA add-on (already in HA base images).
# To combine both, you can instead:

# Start again with Pulse image as base
FROM rcourtman/pulse:latest

# Switch to bash and add s6 overlay for HA if needed, but
# Home Assistant will just run /run.sh, so we can keep it simple.

# Copy our run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Default command for Home Assistant add-on
CMD ["/run.sh"]
