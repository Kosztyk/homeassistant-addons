ARG BUILD_FROM
FROM $BUILD_FROM

# Install tools we need to fetch and unpack the agent binary
RUN apk add --no-cache \
    curl \
    tar \
    ca-certificates

# Copy the main run script into the container
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Start the add-on
CMD [ "/run.sh" ]
