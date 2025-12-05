ARG BUILD_FROM=node:18-alpine
FROM ${BUILD_FROM}

# Install required packages
RUN apk add --no-cache \
    ffmpeg \
    python3 \
    make \
    g++ \
    jq \
    bash \
    su-exec

# Create app directory
WORKDIR /app

# Clone ConvertX repository
RUN git clone https://github.com/C4illin/ConvertX.git . \
    && git checkout main

# Install dependencies
RUN npm ci

# Create the directory structure we'll use
RUN mkdir -p /addons/convertx/data/db

# Copy entrypoint script
COPY rootfs/ /

# Set permissions on entrypoint
RUN chmod +x /usr/local/bin/convertx-entrypoint.sh

# Set ownership
RUN chown -R node:node /app /addons/convertx

# Expose port
EXPOSE 3000

# Simple health check - adjust based on ConvertX's actual endpoints
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Use our entrypoint
ENTRYPOINT ["/usr/local/bin/convertx-entrypoint.sh"]
