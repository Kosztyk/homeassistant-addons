ARG BUILD_ARCH=amd64

FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.21

ARG BUILD_VERSION

# Install tools we need to fetch and unpack the agent binary, plus smartmontools for disk temps
RUN apk add --no-cache \
    curl \
    tar \
    ca-certificates \
    smartmontools

# Copy the main run script into the container
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Start the add-on
CMD [ "/run.sh" ]
