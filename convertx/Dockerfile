# If you want to use your custom image with ClamAV support:
# ARG BUILD_FROM=kosztyk/convertx-clamav:user
# FROM ${BUILD_FROM}

# Using upstream ConvertX image by default:
ARG BUILD_FROM=ghcr.io/c4illin/convertx:latest
FROM ${BUILD_FROM}

USER root

# Install jq to parse /data/options.json in the entrypoint (works on Alpine/Debian/RHEL-ish)
RUN if command -v apk >/dev/null 2>&1; then \
      apk add --no-cache jq; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*; \
    elif command -v microdnf >/dev/null 2>&1; then \
      microdnf install -y jq && microdnf clean all; \
    else \
      echo "WARN: could not detect package manager to install jq" >&2; \
    fi

COPY rootfs/ /

RUN chmod +x /usr/local/bin/convertx-entrypoint.sh

# Keep the original CMD from the base image, only override ENTRYPOINT.
ENTRYPOINT ["/usr/local/bin/convertx-entrypoint.sh"]
