#!/bin/sh
set -e

# Home Assistant add-on data directory
DATA_DIR="/data"
OPTIONS_FILE="${DATA_DIR}/options.json"

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

# Set ownership and permissions - CRITICAL for SQLite
# Try to set ownership to node user (UID 1000 in Node.js alpine images)
if [ -f /etc/passwd ] && grep -q "^node:" /etc/passwd; then
    chown -R node:node "${DATA_DIR}" 2>/dev/null || true
else
    # Fallback to 1000:1000 (typical node user in Docker)
    chown -R 1000:1000 "${DATA_DIR}" 2>/dev/null || true
fi

# Ensure write permissions
chmod -R 755 "${DATA_DIR}" 2>/dev/null || true
chmod 777 "${DATA_DIR}" 2>/dev/null || true

# Create the database directory specifically
DB_DIR="${DATA_DIR}/db"
mkdir -p "${DB_DIR}"
chmod 777 "${DB_DIR}" 2>/dev/null || true

# Default values
JWT_SECRET_DEFAULT=""
ACCOUNT_REGISTRATION_DEFAULT="true"  # Changed to true for first run
HTTP_ALLOWED_DEFAULT="false"
ALLOW_UNAUTHENTICATED_DEFAULT="false"
AUTO_DELETE_EVERY_N_HOURS_DEFAULT="24"
TZ_DEFAULT="Europe/Bucharest"
CLAMAV_URL_DEFAULT=""
DATABASE_URL_DEFAULT="file:${DB_DIR}/convertx.db"  # SQLite database path

# Read configuration from Home Assistant
if [ -f "${OPTIONS_FILE}" ] && command -v jq >/dev/null 2>&1; then
    JWT_SECRET=$(jq -r '.jwt_secret // empty' "${OPTIONS_FILE}")
    ACCOUNT_REGISTRATION=$(jq -r '.account_registration // "'"${ACCOUNT_REGISTRATION_DEFAULT}"'"' "${OPTIONS_FILE}")
    HTTP_ALLOWED=$(jq -r '.http_allowed // "'"${HTTP_ALLOWED_DEFAULT}"'"' "${OPTIONS_FILE}")
    ALLOW_UNAUTHENTICATED=$(jq -r '.allow_unauthenticated // "'"${ALLOW_UNAUTHENTICATED_DEFAULT}"'"' "${OPTIONS_FILE}")
    AUTO_DELETE_EVERY_N_HOURS=$(jq -r '.auto_delete_hours // "'"${AUTO_DELETE_EVERY_N_HOURS_DEFAULT}"'"' "${OPTIONS_FILE}")
    CLAMAV_URL=$(jq -r '.clamav_url // empty' "${OPTIONS_FILE}")
    TZ_VAL=$(jq -r '.tz // "'"${TZ_DEFAULT}"'"' "${OPTIONS_FILE}")
else
    # Use defaults
    JWT_SECRET="${JWT_SECRET_DEFAULT}"
    ACCOUNT_REGISTRATION="${ACCOUNT_REGISTRATION_DEFAULT}"
    HTTP_ALLOWED="${HTTP_ALLOWED_DEFAULT}"
    ALLOW_UNAUTHENTICATED="${ALLOW_UNAUTHENTICATED_DEFAULT}"
    AUTO_DELETE_EVERY_N_HOURS="${AUTO_DELETE_EVERY_N_HOURS_DEFAULT}"
    CLAMAV_URL="${CLAMAV_URL_DEFAULT}"
    TZ_VAL="${TZ_DEFAULT}"
fi

# Export environment variables
export JWT_SECRET="${JWT_SECRET}"
export ACCOUNT_REGISTRATION="${ACCOUNT_REGISTRATION}"
export HTTP_ALLOWED="${HTTP_ALLOWED}"
export ALLOW_UNAUTHENTICATED="${ALLOW_UNAUTHENTICATED}"
export AUTO_DELETE_EVERY_N_HOURS="${AUTO_DELETE_EVERY_N_HOURS}"
export CLAMAV_URL="${CLAMAV_URL}"
export TZ="${TZ_VAL}"
export NODE_ENV="production"

# ConvertX might need DATABASE_URL environment variable
# Check ConvertX source to see if it uses this
export DATABASE_URL="${DATABASE_URL_DEFAULT}"

# Create symbolic link for persistent data
# This ensures the app sees /app/data but it's actually in /data
if [ ! -L "/app/data" ]; then
    if [ -d "/app/data" ]; then
        # Backup existing data
        mv "/app/data" "/app/data.bak"
    fi
    ln -sf "${DATA_DIR}" "/app/data"
fi

# Also link the database directory
if [ ! -L "/app/db" ]; then
    ln -sf "${DB_DIR}" "/app/db"
fi

# Fix permissions on the database file if it exists
DB_FILE="${DB_DIR}/convertx.db"
if [ -f "${DB_FILE}" ]; then
    echo "Found existing database: ${DB_FILE}"
    ls -la "${DB_FILE}"
    chmod 666 "${DB_FILE}" 2>/dev/null || true
else
    echo "No existing database found. Will create: ${DB_FILE}"
    # Ensure the directory is writable
    touch "${DB_FILE}" 2>/dev/null || true
    chmod 666 "${DB_FILE}" 2>/dev/null || true
fi

echo "=========================================="
echo "ConvertX Configuration:"
echo "=========================================="
echo "Data Directory: ${DATA_DIR}"
echo "Database Directory: ${DB_DIR}"
echo "Database File: ${DB_FILE}"
echo "ACCOUNT_REGISTRATION: ${ACCOUNT_REGISTRATION}"
echo "HTTP_ALLOWED: ${HTTP_ALLOWED}"
echo "ALLOW_UNAUTHENTICATED: ${ALLOW_UNAUTHENTICATED}"
echo "AUTO_DELETE_EVERY_N_HOURS: ${AUTO_DELETE_EVERY_N_HOURS}"
echo "TIMEZONE: ${TZ_VAL}"
echo "CLAMAV_URL: ${CLAMAV_URL:-'Not set'}"
echo "JWT_SECRET: $(if [ -n "${JWT_SECRET}" ]; then echo "Set"; else echo "Using randomUUID()"; fi)"
echo "=========================================="

# Check permissions
echo ""
echo "Directory Permissions:"
ls -la "${DATA_DIR}/" 2>/dev/null || echo "Cannot list ${DATA_DIR}"
echo ""
if [ -f "${DB_FILE}" ]; then
    echo "Database file permissions:"
    ls -la "${DB_FILE}"
fi
echo ""

# Important warning about authentication
if [ "${ACCOUNT_REGISTRATION}" = "false" ]; then
    echo "⚠️  WARNING: Account registration is disabled!"
    echo "   If you don't have an existing account, you won't be able to login."
    echo "   Set 'account_registration' to true in the add-on options to create an account first."
    echo ""
fi

# Check if we need to run database migrations
# ConvertX might use Prisma or similar ORM
if [ -f "/app/package.json" ]; then
    cd /app
    # Check if prisma is in package.json
    if grep -q "prisma" package.json || [ -f "prisma/schema.prisma" ]; then
        echo "Running database migrations..."
        npx prisma migrate deploy 2>/dev/null || echo "No Prisma migrations found or failed"
    fi
    
    # Check for any other migration commands
    if [ -f "package.json" ] && grep -q '"migrate"' package.json; then
        echo "Running custom migrations..."
        npm run migrate 2>/dev/null || true
    fi
fi

echo "Starting ConvertX..."
echo "=========================================="

# Switch to node user and start the application
# Using exec to properly handle signals
exec su-exec node:node npm start
