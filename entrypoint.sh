#!/bin/sh
set -e

# aprsc Docker Entrypoint Script
# Generates configuration from environment variables if no config file exists

CONFIG_FILE="/etc/aprsc/aprsc.conf"

# Environment variables with defaults
APRSC_SERVER_ID="${APRSC_SERVER_ID:-NOCALL}"
APRSC_PASSCODE="${APRSC_PASSCODE:--1}"
APRSC_MY_ADMIN="${APRSC_MY_ADMIN:-Docker User}"
APRSC_MY_EMAIL="${APRSC_MY_EMAIL:-root@localhost}"
APRSC_RUN_DIR="${APRSC_RUN_DIR:-/var/run/aprsc}"
APRSC_LOG_ROTATE="${APRSC_LOG_ROTATE:-10 5}"

# Listener configuration
APRSC_ENABLE_FULL_FEED="${APRSC_ENABLE_FULL_FEED:-yes}"
APRSC_FULL_FEED_PORT="${APRSC_FULL_FEED_PORT:-10152}"
APRSC_ENABLE_IGATE="${APRSC_ENABLE_IGATE:-yes}"
APRSC_IGATE_PORT="${APRSC_IGATE_PORT:-14580}"
APRSC_ENABLE_UDP_SUBMIT="${APRSC_ENABLE_UDP_SUBMIT:-yes}"
APRSC_UDP_SUBMIT_PORT="${APRSC_UDP_SUBMIT_PORT:-8080}"

# HTTP configuration
APRSC_HTTP_STATUS_PORT="${APRSC_HTTP_STATUS_PORT:-14501}"
APRSC_HTTP_UPLOAD_PORT="${APRSC_HTTP_UPLOAD_PORT:-8080}"

# Uplink configuration
APRSC_UPLINK_ENABLED="${APRSC_UPLINK_ENABLED:-no}"
APRSC_UPLINK_SERVER="${APRSC_UPLINK_SERVER:-rotate.aprs2.net}"
APRSC_UPLINK_PORT="${APRSC_UPLINK_PORT:-10152}"
APRSC_UPLINK_TYPE="${APRSC_UPLINK_TYPE:-full}"

# Timeout configuration
APRSC_UPSTREAM_TIMEOUT="${APRSC_UPSTREAM_TIMEOUT:-15s}"
APRSC_CLIENT_TIMEOUT="${APRSC_CLIENT_TIMEOUT:-48h}"

# Resource limits
APRSC_MAX_CLIENTS="${APRSC_MAX_CLIENTS:-500}"
APRSC_FILE_LIMIT="${APRSC_FILE_LIMIT:-10000}"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "No configuration file found at $CONFIG_FILE"
    echo "Generating configuration from environment variables..."

    # Create configuration directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # Generate configuration file
    cat > "$CONFIG_FILE" << EOF
# aprsc configuration - Generated from environment variables
# $(date)

# Server identification
ServerId $APRSC_SERVER_ID
PassCode $APRSC_PASSCODE

# Administrator information
MyAdmin "$APRSC_MY_ADMIN"
MyEmail $APRSC_MY_EMAIL

# Directories
RunDir $APRSC_RUN_DIR

# Log rotation
LogRotate $APRSC_LOG_ROTATE

# Timeouts
UpstreamTimeout $APRSC_UPSTREAM_TIMEOUT
ClientTimeout $APRSC_CLIENT_TIMEOUT

# Resource limits
MaxClients $APRSC_MAX_CLIENTS
FileLimit $APRSC_FILE_LIMIT

EOF

    # Add listeners based on environment variables
    if [ "$APRSC_ENABLE_FULL_FEED" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Full feed port
Listen "Full feed" fullfeed tcp :: $APRSC_FULL_FEED_PORT hidden
Listen "" fullfeed udp :: $APRSC_FULL_FEED_PORT hidden

EOF
    fi

    if [ "$APRSC_ENABLE_IGATE" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Client-defined filters port
Listen "Client-Defined Filters" igate tcp :: $APRSC_IGATE_PORT
Listen "" igate udp :: $APRSC_IGATE_PORT

EOF
    fi

    if [ "$APRSC_ENABLE_UDP_SUBMIT" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# UDP submission port
Listen "UDP submit" udpsubmit udp :: $APRSC_UDP_SUBMIT_PORT

EOF
    fi

    # Add HTTP configuration
    cat >> "$CONFIG_FILE" << EOF
# HTTP status page
HTTPStatus 0.0.0.0 $APRSC_HTTP_STATUS_PORT

# HTTP upload
HTTPUpload 0.0.0.0 $APRSC_HTTP_UPLOAD_PORT

EOF

    # Add uplink if enabled
    if [ "$APRSC_UPLINK_ENABLED" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Uplink configuration
Uplink "$APRSC_UPLINK_SERVER" $APRSC_UPLINK_TYPE tcp $APRSC_UPLINK_SERVER $APRSC_UPLINK_PORT

EOF
    fi

    echo "Configuration file generated successfully"
    echo "Server ID: $APRSC_SERVER_ID"
    echo "Uplink enabled: $APRSC_UPLINK_ENABLED"

    # Show warning if using default callsign
    if [ "$APRSC_SERVER_ID" = "NOCALL" ]; then
        echo ""
        echo "WARNING: Using default callsign 'NOCALL'"
        echo "Please set APRSC_SERVER_ID environment variable to your callsign"
        echo "Example: -e APRSC_SERVER_ID=YOUR-CALL"
    fi

    # Show warning if using invalid passcode
    if [ "$APRSC_PASSCODE" = "-1" ]; then
        echo ""
        echo "WARNING: Using invalid passcode"
        echo "Please set APRSC_PASSCODE environment variable"
        echo "Generate at: https://apps.magicbug.co.uk/passcode/"
    fi
else
    echo "Using existing configuration file: $CONFIG_FILE"
fi

# Execute aprsc with all arguments
exec "$@"
