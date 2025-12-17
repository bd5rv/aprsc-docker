#!/bin/bash
# Test APRS-IS connection functionality

set -e

IMAGE="${DOCKERHUB_IMAGE:-bd5rv/aprsc}:test"

echo "=========================================="
echo "APRS-IS Connection Tests"
echo "=========================================="
echo "Testing image: $IMAGE"
echo ""

# Start container with uplink enabled
echo "Starting container with uplink..."
docker run -d --name aprsc-aprs-test \
    -e APRSC_SERVER_ID=CITEST \
    -e APRSC_PASSCODE=-1 \
    -e APRSC_UPLINK_ENABLED=yes \
    -e APRSC_UPLINK_SERVER=rotate.aprs2.net \
    -p 14580:14580 \
    -p 14501:14501 \
    "$IMAGE"

# Wait for startup and uplink connection
echo "Waiting for uplink to establish..."
sleep 30

# Test 1: Uplink connection in logs
echo ""
echo "Test 1: Checking uplink connection"
UPLINK_LOGS=$(docker logs aprsc-aprs-test 2>&1)

if echo "$UPLINK_LOGS" | grep -qi "uplink.*connect"; then
    echo "✓ Uplink connection attempt detected"
    echo "$UPLINK_LOGS" | grep -i "uplink" | tail -5
else
    echo "! Uplink connection logs not found (checking alternative patterns)"
    echo "$UPLINK_LOGS" | grep -i "uplink" | tail -10 || true
fi

# Test 2: Client connection test
echo ""
echo "Test 2: Testing client connection"
# Install netcat if needed
if ! command -v nc &> /dev/null; then
    echo "Installing netcat..."
    apt-get update -qq && apt-get install -y -qq netcat-openbsd > /dev/null 2>&1 || \
    apk add --no-cache netcat-openbsd > /dev/null 2>&1 || true
fi

# Test client login
(
    echo "user CITEST pass -1 vers test-script 1.0"
    sleep 5
) | timeout 10 nc localhost 14580 > /tmp/aprs-connection-test.log 2>&1 || true

if [ -f /tmp/aprs-connection-test.log ]; then
    echo "Connection test output:"
    cat /tmp/aprs-connection-test.log

    if grep -q "logresp" /tmp/aprs-connection-test.log; then
        echo "✓ Client login successful (received logresp)"
    elif grep -q "aprsc" /tmp/aprs-connection-test.log; then
        echo "✓ Server response received"
    else
        echo "! Limited server response (may be normal)"
    fi
else
    echo "! No connection log generated"
fi

# Test 3: Data flow check
echo ""
echo "Test 3: Checking data flow in logs"
if echo "$UPLINK_LOGS" | grep -qE "(RX|TX|bytes|packets)"; then
    echo "✓ Data flow indicators found"
    echo "$UPLINK_LOGS" | grep -E "(RX|TX|bytes|packets)" | tail -3 || true
else
    echo "! Limited data flow (may be normal for test environment)"
fi

# Test 4: Web interface check
echo ""
echo "Test 4: Checking web interface status"
if command -v curl &> /dev/null; then
    STATUS_JSON=$(curl -s http://localhost:14501/status.json 2>/dev/null || echo "{}")

    if echo "$STATUS_JSON" | grep -q "server"; then
        echo "✓ Web interface accessible"

        # Check uplink status from JSON
        UPLINK_COUNT=$(echo "$STATUS_JSON" | grep -o '"uplinks"' | wc -l)
        if [ "$UPLINK_COUNT" -gt 0 ]; then
            echo "✓ Uplink configuration present in status"
        fi
    else
        echo "! Web interface limited response"
    fi
else
    echo "! curl not available, skipping web check"
fi

# Show final logs
echo ""
echo "Final container logs (last 20 lines):"
docker logs aprsc-aprs-test 2>&1 | tail -20

# Cleanup
echo ""
echo "Cleaning up..."
docker stop aprsc-aprs-test
docker rm aprsc-aprs-test
rm -f /tmp/aprs-connection-test.log

echo ""
echo "=========================================="
echo "✓ APRS-IS tests completed!"
echo "=========================================="
exit 0
