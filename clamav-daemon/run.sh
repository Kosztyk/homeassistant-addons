#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Starting ClamAV Daemon add-on"

# -------------------------------------------------------------------
# Read configuration from /data/options.json
# -------------------------------------------------------------------
LISTEN_IP="$(bashio::config 'listen_ip')"
LISTEN_PORT="$(bashio::config 'listen_port')"
MAX_FILE_SIZE_MB="$(bashio::config 'max_file_size_mb')"
STREAM_MAX_LENGTH_MB="$(bashio::config 'stream_max_length_mb')"

if bashio::config.is_empty 'listen_ip'; then
    bashio::log.warning "listen_ip not set, defaulting to 0.0.0.0"
    LISTEN_IP="0.0.0.0"
fi

if bashio::config.is_empty 'listen_port'; then
    bashio::log.warning "listen_port not set, defaulting to 3310"
    LISTEN_PORT=3310
fi

if bashio::config.is_empty 'max_file_size_mb'; then
    bashio::log.warning "max_file_size_mb not set, defaulting to 250"
    MAX_FILE_SIZE_MB=250
fi

if bashio::config.is_empty 'stream_max_length_mb'; then
    bashio::log.warning "stream_max_length_mb not set, defaulting to 250"
    STREAM_MAX_LENGTH_MB=250
fi

bashio::log.info "Configured listen_ip=${LISTEN_IP}, listen_port=${LISTEN_PORT}"
bashio::log.info "MaxFileSize=${MAX_FILE_SIZE_MB}M, StreamMaxLength=${STREAM_MAX_LENGTH_MB}M"

# -------------------------------------------------------------------
# Prepare directories
# -------------------------------------------------------------------
mkdir -p /var/lib/clamav /var/log/clamav /run/clamav
chown -R root:root /var/lib/clamav /var/log/clamav /run/clamav

# -------------------------------------------------------------------
# Write clamd.conf based on our options
# -------------------------------------------------------------------
bashio::log.info "Writing /etc/clamav/clamd.conf"

cat <<EOF > /etc/clamav/clamd.conf
LogTime yes
LogFile /var/log/clamav/clamd.log
PidFile /run/clamav/clamd.pid
DatabaseDirectory /var/lib/clamav

TCPSocket ${LISTEN_PORT}
TCPAddr ${LISTEN_IP}

User root

ScanMail no
ScanArchive yes
StreamMaxLength ${STREAM_MAX_LENGTH_MB}M
MaxFileSize ${MAX_FILE_SIZE_MB}M

Foreground yes
EOF

# -------------------------------------------------------------------
# Update virus database (freshclam)
# -------------------------------------------------------------------
bashio::log.info "Updating ClamAV database with freshclam (may be rate-limited)..."
if ! freshclam; then
    bashio::log.warning "freshclam failed (possibly rate-limited). Using existing database if present."
fi

# -------------------------------------------------------------------
# Start clamd in foreground
# -------------------------------------------------------------------
bashio::log.info "Starting clamd on ${LISTEN_IP}:${LISTEN_PORT}"
exec clamd -c /etc/clamav/clamd.conf
