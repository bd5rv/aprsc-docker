#!/bin/bash
# Basic container functionality tests

set -e

IMAGE="${DOCKERHUB_IMAGE:-bd5rv/aprsc}:test"

echo "=========================================="
echo "Basic Container Tests"
echo "=========================================="
echo "Testing image: $IMAGE"
echo ""

# Test 1: Container starts
echo "Test 1: Container starts successfully"
docker run -d --name aprsc-test \
    -e APRSC_SERVER_ID=TEST \
    -e APRSC_PASSCODE=-1 \
    -p 14580:14580 \
    -p 14501:14501 \
    "$IMAGE"

# Wait for startup
echo "Waiting for container to start..."
sleep 15

# Test 2: Process is running
echo ""
echo "Test 2: aprsc process is running"
if docker exec aprsc-test pgrep aprsc > /dev/null; then
    echo "✓ aprsc process found"
else
    echo "✗ aprsc process not found"
    docker logs aprsc-test
    docker stop aprsc-test && docker rm aprsc-test
    exit 1
fi

# Test 3: Version check
echo ""
echo "Test 3: Version verification"
VERSION=$(docker exec aprsc-test /opt/aprsc/sbin/aprsc --version 2>&1 | head -1)
echo "Version: $VERSION"
if echo "$VERSION" | grep -q "aprsc"; then
    echo "✓ Version output valid"
else
    echo "✗ Invalid version output"
    docker stop aprsc-test && docker rm aprsc-test
    exit 1
fi

# Test 4: Configuration generated
echo ""
echo "Test 4: Configuration file exists"
if docker exec aprsc-test test -f /etc/aprsc/aprsc.conf; then
    echo "✓ Configuration file exists"
    echo ""
    echo "Configuration preview:"
    docker exec aprsc-test head -20 /etc/aprsc/aprsc.conf
else
    echo "✗ Configuration file missing"
    docker stop aprsc-test && docker rm aprsc-test
    exit 1
fi

# Test 5: Ports listening
echo ""
echo "Test 5: Ports are listening"
sleep 5
if docker exec aprsc-test netstat -tuln 2>/dev/null | grep -E ':(14580|14501)'; then
    echo "✓ Required ports are listening"
elif docker exec aprsc-test ss -tuln 2>/dev/null | grep -E ':(14580|14501)'; then
    echo "✓ Required ports are listening (ss)"
else
    echo "✗ Ports not listening"
    docker logs aprsc-test
    docker stop aprsc-test && docker rm aprsc-test
    exit 1
fi

# Test 6: Architecture check
echo ""
echo "Test 6: Architecture verification"
ARCH=$(docker exec aprsc-test uname -m)
echo "Architecture: $ARCH"

# Test 7: Health check status (if defined)
echo ""
echo "Test 7: Container health check"
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' aprsc-test 2>/dev/null || echo "none")
echo "Health status: $HEALTH_STATUS"

if [ "$HEALTH_STATUS" = "unhealthy" ]; then
    echo "✗ Container is unhealthy"
    docker logs aprsc-test
    docker stop aprsc-test && docker rm aprsc-test
    exit 1
fi

# Cleanup
echo ""
echo "Cleaning up..."
docker stop aprsc-test
docker rm aprsc-test

echo ""
echo "=========================================="
echo "✓ All basic tests passed!"
echo "=========================================="
exit 0
