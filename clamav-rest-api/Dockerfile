FROM benzino77/clamav-rest-api:latest

# Always run as root in the add-on so we can read /data/options.json
USER root

# We need bash & jq to read /data/options.json from HA.
# Base image is Debian/Ubuntu-style, so use apt-get.
RUN apt-get update \
    && apt-get install -y jq bash \
    && rm -rf /var/lib/apt/lists/*

# Copy our wrapper script to a safe path
COPY run.sh /usr/local/bin/clamav-addon-run.sh

# Workdir where the upstream app lives
WORKDIR /clamav-rest-api

EXPOSE 3000

# Run our wrapper via bash
CMD ["bash", "/usr/local/bin/clamav-addon-run.sh"]
