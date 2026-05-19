#!/bin/bash
# Script to build and push multi-architecture aprsc Docker image to Docker Hub
# Supports: linux/amd64, linux/arm64, linux/arm/v7
# This script will NOT be committed to git repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-bd5rv}"
IMAGE_NAME="aprsc"
PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
BUILDER_NAME="aprsc-multiarch-builder"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Multi-Architecture Docker Build & Push${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get aprsc full version by building a temporary version-detect image
echo -e "${YELLOW}Detecting aprsc version...${NC}"

# Build a fresh temporary image to detect the latest upstream version
echo -e "${YELLOW}Building temporary image for version detection...${NC}"
docker build --no-cache --quiet --target builder -t aprsc-version-detect:tmp . > /dev/null 2>&1 || true
APRSC_FULL_VERSION=$(docker run --rm aprsc-version-detect:tmp /tmp/aprsc-install/opt/aprsc/sbin/aprsc --version 2>&1 | grep -oP 'aprsc \K[0-9]+\.[0-9]+\.[0-9]+(-g[0-9a-f]+)?' | head -1 || echo "")
docker rmi aprsc-version-detect:tmp > /dev/null 2>&1 || true

# Fallback to existing local build if temporary build failed
if [ -z "$APRSC_FULL_VERSION" ]; then
    echo -e "${YELLOW}Falling back to existing local build...${NC}"
    APRSC_FULL_VERSION=$(docker run --rm aprsc-docker-aprsc:latest /opt/aprsc/sbin/aprsc --version 2>/dev/null | grep -oP 'aprsc \K[0-9]+\.[0-9]+\.[0-9]+(-g[0-9a-f]+)?' | head -1 || echo "")
fi

# Final fallback
if [ -z "$APRSC_FULL_VERSION" ]; then
    echo -e "${RED}ERROR: Could not detect aprsc version${NC}"
    exit 1
fi

if [ -z "$APRSC_FULL_VERSION" ]; then
    echo -e "${RED}ERROR: Could not detect aprsc version${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected aprsc version: ${APRSC_FULL_VERSION}${NC}"
echo ""

# Parse version (remove git hash for semantic version)
APRSC_VERSION=$(echo $APRSC_FULL_VERSION | sed 's/-g[0-9a-f]*//')
MAJOR=$(echo $APRSC_VERSION | cut -d. -f1)
MINOR=$(echo $APRSC_VERSION | cut -d. -f2)

# Generate tags
FULL_GIT_TAG="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${APRSC_FULL_VERSION}"
SEMANTIC_TAG="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${APRSC_VERSION}"
MINOR_TAG="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${MAJOR}.${MINOR}"
MAJOR_TAG="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${MAJOR}"
LATEST_TAG="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"

# Build summary
echo -e "${BLUE}Build Configuration:${NC}"
echo "  Repository: ${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
echo "  Version: ${APRSC_FULL_VERSION}"
echo "  Platforms: ${PLATFORMS}"
echo ""
echo -e "${BLUE}Tags to be created:${NC}"
echo "  - ${APRSC_FULL_VERSION} (full version with git hash)"
echo "  - ${APRSC_VERSION} (semantic version)"
echo "  - ${MAJOR}.${MINOR} (major.minor)"
echo "  - ${MAJOR} (major only)"
echo "  - latest"
echo ""

# Confirm (skip in CI mode)
if [ "$CI_MODE" = "true" ]; then
    echo -e "${GREEN}CI mode enabled - proceeding automatically${NC}"
    echo ""
else
    read -p "Continue with multi-arch build and push? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi
    echo ""
fi

# Check if logged in
echo -e "${YELLOW}Checking Docker Hub login...${NC}"
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo -e "${YELLOW}Not logged in to Docker Hub. Please login:${NC}"
    docker login
else
    CURRENT_USER=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
    echo -e "${GREEN}✓ Logged in as: ${CURRENT_USER}${NC}"
fi
echo ""

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
echo -e "${GREEN}✓ Using builder: ${BUILDER_NAME}${NC}"
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
    echo "Make sure QEMU is installed: docker run --privileged --rm tonistiigi/binfmt --install all"
    exit 1
fi
echo -e "${GREEN}✓ All required platforms supported${NC}"
echo ""

# Build and push multi-arch images
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building Multi-Architecture Images${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Building for: ${PLATFORMS}${NC}"
echo -e "${YELLOW}This will take approximately 15-20 minutes...${NC}"
echo ""

START_TIME=$(date +%s)

# Build and push all architectures with all tags
docker buildx build \
    --no-cache \
    --platform ${PLATFORMS} \
    --push \
    -t ${FULL_GIT_TAG} \
    -t ${SEMANTIC_TAG} \
    -t ${MINOR_TAG} \
    -t ${MAJOR_TAG} \
    -t ${LATEST_TAG} \
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
    echo -e "${GREEN}Successfully Built & Pushed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}✓ Build completed in ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
    echo ""
    echo -e "${BLUE}Repository:${NC} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
    echo -e "${BLUE}Version:${NC} ${APRSC_FULL_VERSION}"
    echo -e "${BLUE}Platforms:${NC} ${PLATFORMS}"
    echo ""
    echo -e "${BLUE}Available tags:${NC}"
    echo "  - ${APRSC_FULL_VERSION} (full version with git hash)"
    echo "  - ${APRSC_VERSION} (semantic version)"
    echo "  - ${MAJOR}.${MINOR} (major.minor)"
    echo "  - ${MAJOR} (major)"
    echo "  - latest"
    echo ""
    echo -e "${BLUE}Pull commands:${NC}"
    echo "  docker pull ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
    echo "  docker pull ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${APRSC_FULL_VERSION}"
    echo "  docker pull ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${APRSC_VERSION}"
    echo ""
    echo -e "${BLUE}Platform-specific pulls:${NC}"
    echo "  docker pull --platform linux/amd64 ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
    echo "  docker pull --platform linux/arm64 ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
    echo "  docker pull --platform linux/arm/v7 ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
    echo ""
    echo -e "${BLUE}Inspect manifest list:${NC}"
    echo "  docker buildx imagetools inspect ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
    echo ""
    echo -e "${BLUE}View on Docker Hub:${NC}"
    echo "  https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
    echo ""
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Build Failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${RED}Build failed after ${BUILD_MINUTES}m ${BUILD_SECONDS}s${NC}"
    exit 1
fi
