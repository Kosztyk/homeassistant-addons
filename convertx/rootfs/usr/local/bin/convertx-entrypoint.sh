#!/bin/sh
set -e

OPTIONS_FILE="/data/options.json"

# Make sure /data exists and /app/data points to it (persistent storage)
mkdir -p /data
if [ ! -L /app/data ]; then
  # If /app/data exists as a dir or file, remove it and replace with symlink
  if [ -d /app/data ] || [ -f /app/data ]; then
    rm -rf /app/data
  fi
  ln -s /data /app/data
fi

# Try to fix permissions so ConvertX can write its SQLite DB
# (equivalent to "chown -R $USER:$USER path" from README)
# We don't know the exact user ConvertX runs as, so:
#  - first try chown to a common non-root UID (1000)
#  - if that fails, fall back to chmod 777 (this is a homelab-only box anyway)
chown -R 1000:1000 /data 2>/dev/null || chmod -R 777 /data || true

# Defaults – same as in config.yaml
JWT_SECRET_DEFAULT="CHANGE_ME_TO_LONG_RANDOM_STRING"
HTTP_ALLOWED_DEFAULT="true"
TZ_DEFAULT="Europe/Bucharest"
AUTO_DELETE_DEFAULT="720"
CLAMAV_URL_DEFAULT="http://192.168.68.144:3000/api/v1/scan"
ACCOUNT_REGISTRATION_DEFAULT="true"
ALLOW_UNAUTHENTICATED_DEFAULT="false"

JWT_SECRET=""
HTTP_ALLOWED=""
TZ_VAL=""
AUTO_DELETE=""
CLAMAV_URL=""
ACCOUNT_REGISTRATION=""
ALLOW_UNAUTHENTICATED=""

# Read options from HA's /data/options.json if jq is available
if [ -f "$OPTIONS_FILE" ] && command -v jq >/dev/null 2>&1; then
  JWT_SECRET="$(jq -r '.jwt_secret // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  HTTP_ALLOWED="$(jq -r '.http_allowed // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  TZ_VAL="$(jq -r '.tz // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  AUTO_DELETE="$(jq -r '.auto_delete_hours // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  CLAMAV_URL="$(jq -r '.clamav_url // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  ACCOUNT_REGISTRATION="$(jq -r '.account_registration // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
  ALLOW_UNAUTHENTICATED="$(jq -r '.allow_unauthenticated // empty' "$OPTIONS_FILE" 2>/dev/null || true)"
fi

[ -z "$JWT_SECRET" ] && JWT_SECRET="$JWT_SECRET_DEFAULT"
[ -z "$HTTP_ALLOWED" ] && HTTP_ALLOWED="$HTTP_ALLOWED_DEFAULT"
[ -z "$TZ_VAL" ] && TZ_VAL="$TZ_DEFAULT"
[ -z "$AUTO_DELETE" ] && AUTO_DELETE="$AUTO_DELETE_DEFAULT"
[ -z "$CLAMAV_URL" ] && CLAMAV_URL="$CLAMAV_URL_DEFAULT"
[ -z "$ACCOUNT_REGISTRATION" ] && ACCOUNT_REGISTRATION="$ACCOUNT_REGISTRATION_DEFAULT"
[ -z "$ALLOW_UNAUTHENTICATED" ] && ALLOW_UNAUTHENTICATED="$ALLOW_UNAUTHENTICATED_DEFAULT"

export JWT_SECRET="$JWT_SECRET"
export HTTP_ALLOWED="$HTTP_ALLOWED"
export TZ="$TZ_VAL"
export AUTO_DELETE_EVERY_N_HOURS="$AUTO_DELETE"
export CLAMAV_URL="$CLAMAV_URL"
export ACCOUNT_REGISTRATION="$ACCOUNT_REGISTRATION"
export ALLOW_UNAUTHENTICATED="$ALLOW_UNAUTHENTICATED"

echo "=== ConvertX add-on env ==="
echo "  HTTP_ALLOWED=$HTTP_ALLOWED"
echo "  ACCOUNT_REGISTRATION=$ACCOUNT_REGISTRATION"
echo "  ALLOW_UNAUTHENTICATED=$ALLOW_UNAUTHENTICATED"
echo "  AUTO_DELETE_EVERY_N_HOURS=$AUTO_DELETE"
echo "  CLAMAV_URL=$CLAMAV_URL"
echo "  TZ=$TZ_VAL"
echo "  JWT_SECRET length=${#JWT_SECRET}"
echo "  /data permissions:"
ls -ld /data || true
echo "==========================="

# Call the original ConvertX entrypoint, so behaviour matches your Docker setup
if command -v docker-entrypoint.sh >/dev/null 2>&1; then
  exec docker-entrypoint.sh "$@"
elif [ -x /usr/local/bin/docker-entrypoint.sh ]; then
  exec /usr/local/bin/docker-entrypoint.sh "$@"
else
  echo "ERROR: docker-entrypoint.sh not found, cannot start ConvertX" >&2
  exit 1
fi
