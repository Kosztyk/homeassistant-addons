FROM benzino77/clamav-rest-api:latest

# Upstream sets USER node:node, so we switch to root for setup
USER root

# We need jq and a shell to read /data/options.json from HA
RUN apk add --no-cache bash jq

# Put our wrapper in a writable dir
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Go back to the original non-root user used by the image
USER node

# Upstream project lives here (per README and docker examples)
WORKDIR /clamav-rest-api

EXPOSE 3000

# Use our wrapper to read HA options and then start the app
CMD ["bash", "/usr/local/bin/run.sh"]
