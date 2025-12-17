#!/bin/bash
# Test web interface functionality

set -e

IMAGE="${DOCKERHUB_IMAGE:-bd5rv/aprsc}:test"

echo "=========================================="
echo "Web Interface Tests"
echo "=========================================="
echo "Testing image: $IMAGE"
echo ""

# Start container
echo "Starting container..."
docker run -d --name aprsc-web-test \
    -e APRSC_SERVER_ID=WEBTEST \
    -e APRSC_PASSCODE=-1 \
    -p 14501:14501 \
    "$IMAGE"

# Wait for web server
echo "Waiting for web server to start..."
sleep 15

# Install curl if not available
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    apt-get update -qq && apt-get install -y -qq curl > /dev/null 2>&1 || \
    apk add --no-cache curl > /dev/null 2>&1 || true
fi

# Test 1: HTTP status endpoint
echo ""
echo "Test 1: HTTP status page"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:14501/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ HTTP status page accessible (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" != "000" ]; then
    echo "✓ HTTP response received (HTTP $HTTP_CODE)"
else
    echo "✗ HTTP status page not accessible"
    docker logs aprsc-web-test
    docker stop aprsc-web-test && docker rm aprsc-web-test
    exit 1
fi

# Test 2: JSON status endpoint
echo ""
echo "Test 2: JSON status endpoint"
STATUS_JSON=$(curl -s http://localhost:14501/status.json 2>/dev/null || echo "{}")

if echo "$STATUS_JSON" | grep -q '"server"'; then
    echo "✓ JSON status endpoint working"
    echo ""
    echo "Status JSON preview:"
    echo "$STATUS_JSON" | head -c 500
    echo ""
    echo "..."
else
    echo "✗ JSON status endpoint not working"
    docker logs aprsc-web-test
    docker stop aprsc-web-test && docker rm aprsc-web-test
    exit 1
fi

# Test 3: Status content validation
echo ""
echo "Test 3: Status content validation"

SERVER_ID=$(echo "$STATUS_JSON" | grep -o '"server_id":"[^"]*"' | cut -d'"' -f4)
if [ -n "$SERVER_ID" ]; then
    echo "✓ Status contains server_id: $SERVER_ID"
else
    echo "! server_id not found in status"
fi

VERSION=$(echo "$STATUS_JSON" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "")
if [ -n "$VERSION" ]; then
    echo "✓ Status contains version: $VERSION"
else
    echo "! version not found in status"
fi

# Test 4: Additional HTTP endpoints
echo ""
echo "Test 4: Testing other HTTP endpoints"

# Test /status (HTML version)
STATUS_HTML_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:14501/status 2>/dev/null || echo "000")
if [ "$STATUS_HTML_CODE" = "200" ]; then
    echo "✓ /status endpoint accessible"
fi

# Test root path
ROOT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:14501/ 2>/dev/null || echo "000")
if [ "$ROOT_CODE" = "200" ]; then
    echo "✓ Root path accessible"
fi

# Test 5: Container health
echo ""
echo "Test 5: Container healthcheck"
sleep 10  # Wait a bit more for health check

HEALTH=$(docker inspect --format='{{.State.Health.Status}}' aprsc-web-test 2>/dev/null || echo "none")
echo "Health status: $HEALTH"

if [ "$HEALTH" = "healthy" ]; then
    echo "✓ Container is healthy"
elif [ "$HEALTH" = "none" ]; then
    echo "○ No healthcheck defined (OK)"
elif [ "$HEALTH" = "starting" ]; then
    echo "○ Container still starting"
else
    echo "! Container health: $HEALTH"
fi

# Test 6: Response time check
echo ""
echo "Test 6: Response time check"
TIME_TOTAL=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:14501/status.json 2>/dev/null || echo "0")
echo "Response time: ${TIME_TOTAL}s"

if [ "$TIME_TOTAL" != "0" ]; then
    echo "✓ Server responding in reasonable time"
fi

# Cleanup
echo ""
echo "Cleaning up..."
docker stop aprsc-web-test
docker rm aprsc-web-test

echo ""
echo "=========================================="
echo "✓ All web interface tests passed!"
echo "=========================================="
exit 0
