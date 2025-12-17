#!/bin/bash
# APRS-IS Connection Test Script
# Usage: ./test-aprs-connection.sh [server] [port] [callsign]

SERVER="${1:-localhost}"
PORT="${2:-14580}"
CALLSIGN="${3:-N0CALL}"

echo "========================================="
echo "APRS-IS Connection Test"
echo "========================================="
echo "Server: $SERVER"
echo "Port: $PORT"
echo "Callsign: $CALLSIGN"
echo "========================================="
echo ""
echo "Connecting and logging in..."
echo "Press Ctrl+C to exit"
echo ""

# Create a temporary file for commands
CMDFILE=$(mktemp)
trap "rm -f $CMDFILE" EXIT

# Write login command
cat > "$CMDFILE" << EOF
user $CALLSIGN pass -1 vers test-script 1.0
EOF

# Connect and send login, then keep connection open
(
    cat "$CMDFILE"
    echo ""
    echo "# Logged in successfully. Waiting for data..."
    echo "# You can also send filter commands like:"
    echo "#   filter r/35.6/139.7/100    (radius filter: lat/lon/km)"
    echo "#   filter b/CALLSIGN          (buddy filter: specific callsigns)"
    echo "#   filter p/CQ                (prefix filter: callsigns starting with CQ)"
    echo "#   filter t/poimqstunw        (type filter: various packet types)"
    echo ""
    cat  # Keep reading stdin
) | telnet "$SERVER" "$PORT"
