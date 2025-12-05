# Build our add-on image on top of your working image
ARG BUILD_FROM=kosztyk/convertx-clamav:user
FROM ${BUILD_FROM}

USER root

# Install jq so we can parse options.json
RUN if command -v apk >/dev/null 2>&1; then \
      apk add --no-cache jq; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*; \
    elif command -v microdnf >/dev/null 2>&1; then \
      microdnf install -y jq && microdnf clean all; \
    else \
      echo "WARN: could not detect package manager to install jq" >&2; \
    fi

# Our entrypoint wrapper
COPY rootfs/ /

RUN chmod +x /usr/local/bin/convertx-entrypoint.sh

# IMPORTANT: We call the original docker-entrypoint.sh from the base image
ENTRYPOINT ["/usr/local/bin/convertx-entrypoint.sh"]
