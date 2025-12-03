# Build the add-on image from the official Pulse container
FROM rcourtman/pulse:latest

# Our own lightweight entry script that uses /bin/sh (not bash)
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Override upstream entrypoint — always start via our script
ENTRYPOINT ["/run.sh"]
