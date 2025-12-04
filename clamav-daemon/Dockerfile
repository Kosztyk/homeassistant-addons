FROM alpine:3.20

# Run as root so we can read /data/options.json and manage ClamAV dirs
USER root

# Install ClamAV daemon + bash + jq (for reading /data/options.json)
RUN apk add --no-cache clamav-daemon bash jq

# Copy startup script
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

WORKDIR /tmp

EXPOSE 3310

# PID 1 is our script, no s6-overlay involved
CMD ["/usr/local/bin/run.sh"]
