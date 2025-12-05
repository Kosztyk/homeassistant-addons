#!/bin/sh
set -e

# Based on your mount info: /data is mounted from host
PERSISTENT_ROOT="/data"
DB_DIR="${PERSISTENT_ROOT}/db"
DB_FILE="${DB_DIR}/convertx.db"
OPTIONS_FILE="${PERSISTENT_ROOT}/options.json"

echo "=========================================="
echo "ConvertX Add-on Starting"
echo "=========================================="
echo "Persistent root: ${PERSISTENT_ROOT}"
echo "Database directory: ${DB_DIR}"
echo "Database file: ${DB_FILE}"
echo "Options file: ${OPTIONS_FILE}"
echo ""

# Debug: Show what's in /data
echo "Contents of ${PERSISTENT_ROOT}:"
ls -la "${PERSISTENT_ROOT}/" 2>/dev/null || echo "Cannot list ${PERSISTENT_ROOT}"

# Create directory structure
echo ""
echo "Creating directory structure..."
mkdir -p "${DB_DIR}"

# Check current user
echo ""
echo "Current user: $(id)"
echo "Working directory: $(pwd)"
echo ""

# Check what's in /app (where ConvertX is installed)
echo "Contents of /app:"
ls -la /app/ 2>/dev/null | head -20
echo ""

# Check if ConvertX has existing data directory
if [ -d "/app/data" ]; then
    echo "Found /app/data directory:"
    ls -la /app/data/ 2>/dev/null | head -10
else
    echo "No /app/data directory found"
fi

# Set permissions - CRITICAL
echo ""
echo "Setting permissions on ${PERSISTENT_ROOT}..."
echo "Before: $(ls -ld ${PERSISTENT_ROOT} 2>/dev/null || echo 'cannot check')"

# The container runs as root, but ConvertX might run as a different user
# Let's find out what user ConvertX runs as
if [ -f "/app/package.json" ]; then
    echo "Package.json found, checking scripts..."
    cat /app/package.json | grep -A5 -B5 '"scripts"' || true
fi

# Make /data writable by all
chmod 777 "${PERSISTENT_ROOT}" 2>/dev/null || echo "Warning: Could not change /data permissions"
chmod 777 "${DB_DIR}" 2>/dev/null || echo "Warning: Could not change DB directory permissions"

# Read configuration
echo ""
echo "Reading configuration from ${OPTIONS_FILE}..."
if [ -f "${OPTIONS_FILE}" ] && command -v jq >/dev/null 2>&1; then
    echo "✓ Found options.json"
    
    # Show options for debugging
    echo "Options:"
    cat "${OPTIONS_FILE}" | jq . 2>/dev/null || cat "${OPTIONS_FILE}"
    echo ""
    
    # Read all options
    JWT_SECRET=$(jq -r '.jwt_secret // empty' "${OPTIONS_FILE}" 2>/dev/null || echo "")
    ACCOUNT_REGISTRATION=$(jq -r '.account_registration // "false"' "${OPTIONS_FILE}" 2>/dev/null || echo "false")
    HTTP_ALLOWED=$(jq -r '.http_allowed // "false"' "${OPTIONS_FILE}" 2>/dev/null || echo "false")
    ALLOW_UNAUTHENTICATED=$(jq -r '.allow_unauthenticated // "false"' "${OPTIONS_FILE}" 2>/dev/null || echo "false")
    AUTO_DELETE_EVERY_N_HOURS=$(jq -r '.auto_delete_hours // "24"' "${OPTIONS_FILE}" 2>/dev/null || echo "24")
    WEBROOT=$(jq -r '.webroot // empty' "${OPTIONS_FILE}" 2>/dev/null || echo "")
    FFMPEG_ARGS=$(jq -r '.ffmpeg_args // empty' "${OPTIONS_FILE}" 2>/dev/null || echo "")
    HIDE_HISTORY=$(jq -r '.hide_history // "false"' "${OPTIONS_FILE}" 2>/dev/null || echo "false")
    LANGUAGE=$(jq -r '.language // "en"' "${OPTIONS_FILE}" 2>/dev/null || echo "en")
    UNAUTHENTICATED_USER_SHARING=$(jq -r '.unauthenticated_user_sharing // "false"' "${OPTIONS_FILE}" 2>/dev/null || echo "false")
    MAX_CONVERT_PROCESS=$(jq -r '.max_convert_process // "0"' "${OPTIONS_FILE}" 2>/dev/null || echo "0")
    CLAMAV_URL=$(jq -r '.clamav_url // "http://172.0.0.1:3000/api/v1/scan"' "${OPTIONS_FILE}" 2>/dev/null || echo "http://172.0.0.1:3000/api/v1/scan")
    TZ_VAL=$(jq -r '.tz // "Europe/Bucharest"' "${OPTIONS_FILE}" 2>/dev/null || echo "Europe/Bucharest")
    NODE_ENV_VAL=$(jq -r '.NODE_ENV // "production"' "${OPTIONS_FILE}" 2>/dev/null || echo "production")
else
    echo "⚠ No options.json found or jq not available, using defaults"
    JWT_SECRET=""
    ACCOUNT_REGISTRATION="false"
    HTTP_ALLOWED="false"
    ALLOW_UNAUTHENTICATED="false"
    AUTO_DELETE_EVERY_N_HOURS="24"
    WEBROOT=""
    FFMPEG_ARGS=""
    HIDE_HISTORY="false"
    LANGUAGE="en"
    UNAUTHENTICATED_USER_SHARING="false"
    MAX_CONVERT_PROCESS="0"
    CLAMAV_URL="http://172.0.0.1:3000/api/v1/scan"
    TZ_VAL="Europe/Bucharest"
    NODE_ENV_VAL="production"
fi

# Export ALL ConvertX environment variables
export JWT_SECRET="${JWT_SECRET}"
export ACCOUNT_REGISTRATION="${ACCOUNT_REGISTRATION}"
export HTTP_ALLOWED="${HTTP_ALLOWED}"
export ALLOW_UNAUTHENTICATED="${ALLOW_UNAUTHENTICATED}"
export AUTO_DELETE_EVERY_N_HOURS="${AUTO_DELETE_EVERY_N_HOURS}"
export WEBROOT="${WEBROOT}"
export FFMPEG_ARGS="${FFMPEG_ARGS}"
export HIDE_HISTORY="${HIDE_HISTORY}"
export LANGUAGE="${LANGUAGE}"
export UNAUTHENTICATED_USER_SHARING="${UNAUTHENTICATED_USER_SHARING}"
export MAX_CONVERT_PROCESS="${MAX_CONVERT_PROCESS}"
export CLAMAV_URL="${CLAMAV_URL}"
export TZ="${TZ_VAL}"
export NODE_ENV="${NODE_ENV_VAL}"

# Set DATABASE_URL environment variable
# This is the most important part - ConvertX needs to know where the DB is
export DATABASE_URL="file:${DB_FILE}"

echo ""
echo "=========================================="
echo "ConvertX Configuration"
echo "=========================================="
echo "DATABASE_URL: ${DATABASE_URL}"
echo "ACCOUNT_REGISTRATION: ${ACCOUNT_REGISTRATION}"
echo "ALLOW_UNAUTHENTICATED: ${ALLOW_UNAUTHENTICATED}"
echo "JWT_SECRET: $(if [ -n "${JWT_SECRET}" ]; then echo "Set"; else echo "Using randomUUID()"; fi)"
echo "=========================================="
echo ""

# Ensure database file exists and is writable
echo "Setting up database at ${DB_FILE}..."
touch "${DB_FILE}"
chmod 666 "${DB_FILE}" 2>/dev/null || echo "Warning: Could not set database permissions"

echo "Database file info:"
ls -la "${DB_FILE}" 2>/dev/null || echo "Database file not found"

# Test if we can write to the database
echo ""
echo "Testing database write access..."
if sqlite3 "${DB_FILE}" "SELECT 1;" 2>/dev/null; then
    echo "✓ Can access SQLite database"
else
    echo "✗ Cannot access SQLite database"
    echo "Trying to fix permissions..."
    chmod 777 "${PERSISTENT_ROOT}" 2>/dev/null || true
    chmod 777 "${DB_DIR}" 2>/dev/null || true
    chmod 666 "${DB_FILE}" 2>/dev/null || true
fi

# Check if database has tables (is initialized)
echo ""
echo "Checking if database is initialized..."
if sqlite3 "${DB_FILE}" ".tables" 2>/dev/null | grep -q .; then
    echo "✓ Database has tables (already initialized)"
    TABLES=$(sqlite3 "${DB_FILE}" ".tables" 2>/dev/null)
    echo "  Tables found: ${TABLES}"
else
    echo "✗ Database is empty (will be initialized by ConvertX)"
fi

# Authentication warning
if [ "${ACCOUNT_REGISTRATION}" = "false" ] && [ "${ALLOW_UNAUTHENTICATED}" = "false" ]; then
    echo ""
    echo "🚨 IMPORTANT:"
    echo "   Account registration: DISABLED"
    echo "   Unauthenticated access: DISABLED"
    echo "   If no accounts exist, NO ONE CAN LOGIN."
    echo ""
    # Check if any users exist in the database
    if command -v sqlite3 >/dev/null 2>&1 && [ -f "${DB_FILE}" ]; then
        if sqlite3 "${DB_FILE}" "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%user%';" 2>/dev/null | grep -q .; then
            USER_COUNT=$(sqlite3 "${DB_FILE}" "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
            echo "   Found ${USER_COUNT} user(s) in database"
        fi
    fi
fi

echo ""
echo "Starting ConvertX..."
echo "=========================================="

# Check how ConvertX starts
# Looking at your docker ps output, it uses: "bun run dist/src/in…"
# This suggests ConvertX uses Bun runtime, not Node.js
echo "Detected runtime:"
if command -v bun >/dev/null 2>&1; then
    echo "Using Bun runtime"
    # Check what the original entrypoint does
    if [ -f "/app/package.json" ]; then
        echo "Package.json scripts:"
        cat /app/package.json | grep '"scripts"' -A 10
    fi
    
    # Try to start with Bun
    exec bun run dist/src/index.js
else
    echo "Using Node.js runtime"
    # Fallback to Node.js
    exec node dist/src/index.js
fi
