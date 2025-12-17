#!/bin/bash
# Script to test multi-architecture aprsc Docker image builds locally
# This script builds images without pushing to Docker Hub
# Usage: ./test-multiarch-build.sh [platform]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="aprsc-test"
TAG="multiarch"
BUILDER_NAME="aprsc-multiarch-builder"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"

# Parse command line arguments
PLATFORMS="${1:-$DEFAULT_PLATFORMS}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Multi-Architecture Build Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Test Configuration:${NC}"
echo "  Image: ${IMAGE_NAME}:${TAG}"
echo "  Platforms: ${PLATFORMS}"
echo ""

# Count platforms
PLATFORM_COUNT=$(echo "$PLATFORMS" | tr ',' '\n' | wc -l)

# Check/Create buildx builder
echo -e "${YELLOW}Setting up buildx builder...${NC}"
if docker buildx inspect ${BUILDER_NAME} > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Builder '${BUILDER_NAME}' already exists${NC}"
else
    echo -e "${YELLOW}Creating new builder '${BUILDER_NAME}'...${NC}"
    docker buildx create --name ${BUILDER_NAME} --use --bootstrap
    echo -e "${GREEN}✓ Builder created and activated${NC}"
fi

# Use the builder
docker buildx use ${BUILDER_NAME}
echo ""

# Verify platform support
echo -e "${YELLOW}Verifying platform support...${NC}"
SUPPORTED_PLATFORMS=$(docker buildx inspect --bootstrap | grep "Platforms:" | cut -d: -f2)
echo "  Supported: ${SUPPORTED_PLATFORMS}"

# Check if all required platforms are supported
MISSING_PLATFORMS=""
for PLATFORM in ${PLATFORMS//,/ }; do
    if ! echo "$SUPPORTED_PLATFORMS" | grep -q "$PLATFORM"; then
        MISSING_PLATFORMS="${MISSING_PLATFORMS} ${PLATFORM}"
    fi
done

if [ -n "$MISSING_PLATFORMS" ]; then
    echo -e "${RED}ERROR: Missing platform support:${MISSING_PLATFORMS}${NC}"
    echo "Install QEMU with: docker run --privileged --rm tonistiigi/binfmt --install all"
    exit 1
fi
echo -e "${GREEN}✓ All required platforms supported${NC}"
echo ""

# Determine build mode
if [ $PLATFORM_COUNT -eq 1 ]; then
    # Single platform - can load to local Docker
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Building Single Platform (Local)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Building for: ${PLATFORMS}${NC}"
    echo -e "${YELLOW}Image will be loaded to local Docker${NC}"
    echo ""

    START_TIME=$(date +%s)

    docker buildx build \
        --platform ${PLATFORMS} \
        --load \
        -t ${IMAGE_NAME}:${TAG} \
        --progress=plain \
        .

    BUILD_EXIT_CODE=$?
    END_TIME=$(date +%s)
    BUILD_DURATION=$((END_TIME - START_TIME))
    BUILD_MINUTES=$((BUILD_DURATION / 60))
    BUILD_SECONDS=$((BUILD_DURATION % 60))

    echo ""
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Build Successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${GREEN}✓ Build completed in ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
        echo ""
        echo -e "${BLUE}Test commands:${NC}"
        echo ""
        echo "# Check image architecture:"
        echo "  docker run --rm ${IMAGE_NAME}:${TAG} uname -m"
        echo ""
        echo "# Check aprsc version:"
        echo "  docker run --rm ${IMAGE_NAME}:${TAG} /opt/aprsc/sbin/aprsc --version"
        echo ""
        echo "# Start test container:"
        echo "  docker run -d --name aprsc-test -p 14580:14580 -p 14501:14501 ${IMAGE_NAME}:${TAG}"
        echo ""
        echo "# Test APRS connection:"
        echo "  ./test-aprs-connection.sh localhost 14580 TEST"
        echo ""
        echo "# Check logs:"
        echo "  docker logs aprsc-test"
        echo ""
        echo "# Stop and remove test container:"
        echo "  docker stop aprsc-test && docker rm aprsc-test"
        echo ""
        echo "# Remove test image:"
        echo "  docker rmi ${IMAGE_NAME}:${TAG}"
        echo ""
    else
        echo -e "${RED}Build failed after ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
        exit 1
    fi
else
    # Multiple platforms - build only (can't load multiple to local Docker)
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Building Multiple Platforms${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Building for: ${PLATFORMS}${NC}"
    echo -e "${YELLOW}Images will NOT be loaded to local Docker${NC}"
    echo -e "${YELLOW}(Docker does not support loading multi-arch images)${NC}"
    echo ""
    echo -e "${YELLOW}This will take approximately 5-7 minutes per platform...${NC}"
    echo ""

    START_TIME=$(date +%s)

    docker buildx build \
        --platform ${PLATFORMS} \
        -t ${IMAGE_NAME}:${TAG} \
        --progress=plain \
        .

    BUILD_EXIT_CODE=$?
    END_TIME=$(date +%s)
    BUILD_DURATION=$((END_TIME - START_TIME))
    BUILD_MINUTES=$((BUILD_DURATION / 60))
    BUILD_SECONDS=$((BUILD_DURATION % 60))

    echo ""
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Build Successful!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${GREEN}✓ Build completed in ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
        echo ""
        echo -e "${BLUE}Build verified for platforms:${NC}"
        for PLATFORM in ${PLATFORMS//,/ }; do
            echo "  ✓ ${PLATFORM}"
        done
        echo ""
        echo -e "${YELLOW}Note: Multi-platform images were not loaded to local Docker.${NC}"
        echo ""
        echo -e "${BLUE}To test individual platforms:${NC}"
        echo ""
        for PLATFORM in ${PLATFORMS//,/ }; do
            ARCH=$(echo $PLATFORM | cut -d/ -f2)
            echo "# Test ${PLATFORM}:"
            echo "  ./test-multiarch-build.sh ${PLATFORM}"
            echo ""
        done
        echo -e "${BLUE}To push to Docker Hub:${NC}"
        echo "  ./push-to-dockerhub.sh"
        echo ""
    else
        echo -e "${RED}Build failed after ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
        exit 1
    fi
fi
