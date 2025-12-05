ARG BUILD_FROM=node:18-alpine
FROM ${BUILD_FROM}

# Install required packages including su-exec for user switching
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

# Clone ConvertX repository (using specific commit for stability)
RUN git clone https://github.com/C4illin/ConvertX.git . \
    && git checkout main  # Or a specific tag like v1.0.0

# Install dependencies including dev dependencies for potential builds
RUN npm ci

# Create non-root user (already exists in node image, but ensure)
RUN id node || adduser -D -u 1000 -g 1000 node

# Create directory for persistent data
RUN mkdir -p /data/db && chown -R node:node /data

# Copy entrypoint script
COPY rootfs/ /

# Set permissions on entrypoint
RUN chmod +x /usr/local/bin/convertx-entrypoint.sh

# Set ownership of app directory to node user
RUN chown -R node:node /app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

# Use our entrypoint
ENTRYPOINT ["/usr/local/bin/convertx-entrypoint.sh"]
