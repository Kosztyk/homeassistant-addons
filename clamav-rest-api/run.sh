#!/usr/bin/env bash
set -e

echo "[clamav-rest-api addon] Starting wrapper..."

CONFIG_FILE="/data/options.json"

CLAMD_IP_DEFAULT="192.168.68.73"
CLAMD_PORT_DEFAULT=3310
APP_FORM_KEY_DEFAULT="FILES"
APP_MAX_FILE_SIZE_DEFAULT=262144000

if [ -f "$CONFIG_FILE" ]; then
  echo "[clamav-rest-api addon] Reading options from ${CONFIG_FILE}"
  CLAMD_IP=$(jq -r '.clamd_ip // empty' "$CONFIG_FILE")
  CLAMD_PORT=$(jq -r '.clamd_port // empty' "$CONFIG_FILE")
  APP_FORM_KEY=$(jq -r '.app_form_key // empty' "$CONFIG_FILE")
  APP_MAX_FILE_SIZE=$(jq -r '.app_max_file_size // empty' "$CONFIG_FILE")
else
  echo "[clamav-rest-api addon] WARNING: ${CONFIG_FILE} not found, using defaults."
fi

CLAMD_IP="${CLAMD_IP:-$CLAMD_IP_DEFAULT}"
CLAMD_PORT="${CLAMD_PORT:-$CLAMD_PORT_DEFAULT}"
APP_FORM_KEY="${APP_FORM_KEY:-$APP_FORM_KEY_DEFAULT}"
APP_MAX_FILE_SIZE="${APP_MAX_FILE_SIZE:-$APP_MAX_FILE_SIZE_DEFAULT}"

export CLAMD_IP
export CLAMD_PORT
export APP_FORM_KEY
export APP_MAX_FILE_SIZE

echo "[clamav-rest-api addon] Using CLAMD_IP=${CLAMD_IP}, CLAMD_PORT=${CLAMD_PORT}"
echo "[clamav-rest-api addon] APP_FORM_KEY=${APP_FORM_KEY}, APP_MAX_FILE_SIZE=${APP_MAX_FILE_SIZE}"
echo "[clamav-rest-api addon] NODE_ENV=${NODE_ENV:-production}, APP_PORT=${APP_PORT:-3000}"

cd /clamav-rest-api 2>/dev/null || cd /app 2>/dev/null || cd /

echo "[clamav-rest-api addon] Running: npm start"
npm start
