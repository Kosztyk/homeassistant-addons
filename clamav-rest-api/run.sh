#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Starting ClamAV REST API add-on"

CLAMD_IP="$(bashio::config 'clamd_ip')"
CLAMD_PORT="$(bashio::config 'clamd_port')"
APP_FORM_KEY="$(bashio::config 'app_form_key')"
APP_MAX_FILE_SIZE="$(bashio::config 'app_max_file_size')"

if bashio::config.is_empty 'clamd_ip'; then
  bashio::log.error "clamd_ip is required but not set in options!"
  exit 1
fi

if bashio::config.is_empty 'clamd_port'; then
  bashio::log.error "clamd_port is required but not set in options!"
  exit 1
fi

export CLAMD_IP
export CLAMD_PORT
export APP_FORM_KEY
export APP_MAX_FILE_SIZE

bashio::log.info "Using ClamAV daemon at ${CLAMD_IP}:${CLAMD_PORT}"
bashio::log.info "APP_FORM_KEY=${APP_FORM_KEY}, APP_MAX_FILE_SIZE=${APP_MAX_FILE_SIZE}"

cd /opt/app 2>/dev/null || cd /app 2>/dev/null || cd /
bashio::log.info "Starting ClamAV REST API server on port 3000..."
npm start
