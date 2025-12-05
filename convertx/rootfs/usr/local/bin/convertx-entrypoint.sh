#!/bin/sh
set -e

OPTIONS_FILE="/app/data/options.json"
DATA_DIR="/app/data"

# Ensure directory exists
mkdir -p "${DATA_DIR}"

# Set permissions
chown -R 1000:1000 "${DATA_DIR}" 2>/dev/null || chmod -R 777 "${DATA_DIR}" 2>/dev/null || true

# Default values matching ConvertX defaults
JWT_SECRET_DEFAULT=""  # Will use randomUUID() when empty
ACCOUNT_REGISTRATION_DEFAULT="false"
HTTP_ALLOWED_DEFAULT="false"
ALLOW_UNAUTHENTICATED_DEFAULT="false"
AUTO_DELETE_EVERY_N_HOURS_DEFAULT="24"
WEBROOT_DEFAULT=""
FFMPEG_ARGS_DEFAULT=""
HIDE_HISTORY_DEFAULT="false"
LANGUAGE_DEFAULT="en"
UNAUTHENTICATED_USER_SHARING_DEFAULT="false"
MAX_CONVERT_PROCESS_DEFAULT="0"
CLAMAV_URL_DEFAULT="http://172.0.0.1:3000/api/v1/scan"
TZ_DEFAULT="Europe/Bucharest"

# Read Home Assistant options
if [ -f "$OPTIONS_FILE" ] && command -v jq >/dev/null 2>&1; then
  JWT_SECRET=$(jq -r '.jwt_secret // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$JWT_SECRET_DEFAULT")
  ACCOUNT_REGISTRATION=$(jq -r '.account_registration // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$ACCOUNT_REGISTRATION_DEFAULT")
  HTTP_ALLOWED=$(jq -r '.http_allowed // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$HTTP_ALLOWED_DEFAULT")
  ALLOW_UNAUTHENTICATED=$(jq -r '.allow_unauthenticated // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$ALLOW_UNAUTHENTICATED_DEFAULT")
  AUTO_DELETE_EVERY_N_HOURS=$(jq -r '.auto_delete_hours // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$AUTO_DELETE_EVERY_N_HOURS_DEFAULT")
  WEBROOT=$(jq -r '.webroot // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$WEBROOT_DEFAULT")
  FFMPEG_ARGS=$(jq -r '.ffmpeg_args // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$FFMPEG_ARGS_DEFAULT")
  HIDE_HISTORY=$(jq -r '.hide_history // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$HIDE_HISTORY_DEFAULT")
  LANGUAGE=$(jq -r '.language // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$LANGUAGE_DEFAULT")
  UNAUTHENTICATED_USER_SHARING=$(jq -r '.unauthenticated_user_sharing // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$UNAUTHENTICATED_USER_SHARING_DEFAULT")
  MAX_CONVERT_PROCESS=$(jq -r '.max_convert_process // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$MAX_CONVERT_PROCESS_DEFAULT")
  CLAMAV_URL=$(jq -r '.clamav_url // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$CLAMAV_URL_DEFAULT")
  TZ_VAL=$(jq -r '.tz // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$TZ_DEFAULT")
else
  # Use defaults if options.json doesn't exist
  JWT_SECRET="$JWT_SECRET_DEFAULT"
  ACCOUNT_REGISTRATION="$ACCOUNT_REGISTRATION_DEFAULT"
  HTTP_ALLOWED="$HTTP_ALLOWED_DEFAULT"
  ALLOW_UNAUTHENTICATED="$ALLOW_UNAUTHENTICATED_DEFAULT"
  AUTO_DELETE_EVERY_N_HOURS="$AUTO_DELETE_EVERY_N_HOURS_DEFAULT"
  WEBROOT="$WEBROOT_DEFAULT"
  FFMPEG_ARGS="$FFMPEG_ARGS_DEFAULT"
  HIDE_HISTORY="$HIDE_HISTORY_DEFAULT"
  LANGUAGE="$LANGUAGE_DEFAULT"
  UNAUTHENTICATED_USER_SHARING="$UNAUTHENTICATED_USER_SHARING_DEFAULT"
  MAX_CONVERT_PROCESS="$MAX_CONVERT_PROCESS_DEFAULT"
  CLAMAV_URL="$CLAMAV_URL_DEFAULT"
  TZ_VAL="$TZ_DEFAULT"
fi

# Export ALL ConvertX environment variables with exact names
export JWT_SECRET="$JWT_SECRET"
export ACCOUNT_REGISTRATION="$ACCOUNT_REGISTRATION"
export HTTP_ALLOWED="$HTTP_ALLOWED"
export ALLOW_UNAUTHENTICATED="$ALLOW_UNAUTHENTICATED"
export AUTO_DELETE_EVERY_N_HOURS="$AUTO_DELETE_EVERY_N_HOURS"
export WEBROOT="$WEBROOT"
export FFMPEG_ARGS="$FFMPEG_ARGS"
export HIDE_HISTORY="$HIDE_HISTORY"
export LANGUAGE="$LANGUAGE"
export UNAUTHENTICATED_USER_SHARING="$UNAUTHENTICATED_USER_SHARING"
export MAX_CONVERT_PROCESS="$MAX_CONVERT_PROCESS"
export CLAMAV_URL="$CLAMAV_URL"
export TZ="$TZ_VAL"

# Also set NODE_ENV for Node.js applications
export NODE_ENV="production"

echo "=== ConvertX Add-on Configuration ==="
echo "Data Directory: $DATA_DIR"
echo ""
echo "Core Settings:"
echo "  ACCOUNT_REGISTRATION: $ACCOUNT_REGISTRATION"
echo "  HTTP_ALLOWED: $HTTP_ALLOWED"
echo "  ALLOW_UNAUTHENTICATED: $ALLOW_UNAUTHENTICATED"
echo "  AUTO_DELETE_EVERY_N_HOURS: $AUTO_DELETE_EVERY_N_HOURS"
echo ""
echo "Security:"
echo "  JWT_SECRET set: $( [ -n "$JWT_SECRET" ] && echo "Yes (custom)" || echo "No - using randomUUID()" )"
echo "  CLAMAV_URL: $CLAMAV_URL"
echo ""
echo "UI Settings:"
echo "  WEBROOT: ${WEBROOT:-'(empty)'}"
echo "  HIDE_HISTORY: $HIDE_HISTORY"
echo "  LANGUAGE: $LANGUAGE"
echo "  UNAUTHENTICATED_USER_SHARING: $UNAUTHENTICATED_USER_SHARING"
echo ""
echo "Conversion Settings:"
echo "  MAX_CONVERT_PROCESS: $MAX_CONVERT_PROCESS"
echo "  FFMPEG_ARGS: ${FFMPEG_ARGS:-'(empty)'}"
echo ""
echo "System:"
echo "  TIMEZONE: $TZ_VAL"
echo "======================================"

# First run check
FIRST_RUN_FILE="$DATA_DIR/.first-run"
if [ ! -f "$FIRST_RUN_FILE" ] && [ "$ACCOUNT_REGISTRATION" = "false" ]; then
  echo ""
  echo "⚠️  WARNING: ACCOUNT_REGISTRATION is disabled"
  echo "   If this is your first time and you haven't created an account yet,"
  echo "   you won't be able to login!"
  echo "   Consider enabling ACCOUNT_REGISTRATION temporarily in add-on options."
  echo ""
fi

touch "$FIRST_RUN_FILE"

# Call the original entrypoint
if command -v docker-entrypoint.sh >/dev/null 2>&1; then
  exec docker-entrypoint.sh "$@"
elif [ -x /usr/local/bin/docker-entrypoint.sh ]; then
  exec /usr/local/bin/docker-entrypoint.sh "$@"
elif [ -f /app/docker-entrypoint.sh ]; then
  exec /app/docker-entrypoint.sh "$@"
else
  echo "WARNING: Could not find original entrypoint, starting directly..."
  if [ -f /app/package.json ]; then
    cd /app && exec npm start
  else
    echo "ERROR: Cannot start ConvertX - no entrypoint found" >&2
    exit 1
  fi
fi
