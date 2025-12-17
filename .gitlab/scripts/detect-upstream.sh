#!/bin/bash
# Detect upstream aprsc changes
# Compares latest commit SHA with stored state

set -e

UPSTREAM_REPO="https://github.com/hessu/aprsc.git"
STATE_FILE=".gitlab/upstream-state.txt"
BUILD_FLAGS_FILE=".gitlab/build-flags.env"

echo "=========================================="
echo "Detecting Upstream Changes"
echo "=========================================="

# Clone upstream repo (shallow)
echo "Cloning upstream repository..."
git clone --depth=1 --branch=master "$UPSTREAM_REPO" /tmp/aprsc-upstream

# Get latest commit SHA
LATEST_SHA=$(cd /tmp/aprsc-upstream && git rev-parse HEAD)
echo "Latest upstream SHA: $LATEST_SHA"

# Get commit info
cd /tmp/aprsc-upstream
COMMIT_DATE=$(git log -1 --format='%ai')
COMMIT_AUTHOR=$(git log -1 --format='%an')
COMMIT_MESSAGE=$(git log -1 --format='%s')

echo "Commit Date: $COMMIT_DATE"
echo "Author: $COMMIT_AUTHOR"
echo "Message: $COMMIT_MESSAGE"

# Load previous state
cd -
if [ -f "$STATE_FILE" ]; then
    PREVIOUS_SHA=$(cat "$STATE_FILE")
    echo "Previous SHA: $PREVIOUS_SHA"
else
    PREVIOUS_SHA=""
    echo "No previous state found (first run)"
fi

# Compare
if [ "$LATEST_SHA" != "$PREVIOUS_SHA" ] || [ "${FORCE_BUILD:-false}" = "true" ]; then
    echo ""
    echo "✓ UPSTREAM CHANGED - Build needed"
    echo "  Previous: ${PREVIOUS_SHA:-none}"
    echo "  Latest:   $LATEST_SHA"
    echo ""

    # Write flags
    echo "UPSTREAM_CHANGED=true" > "$BUILD_FLAGS_FILE"
    echo "UPSTREAM_SHA=$LATEST_SHA" >> "$BUILD_FLAGS_FILE"

    # Update state file
    echo "$LATEST_SHA" > "$STATE_FILE"

    # Save commit info for later use
    cat > .gitlab/upstream-commit-info.txt <<EOF
Upstream commit: $LATEST_SHA
Date: $COMMIT_DATE
Author: $COMMIT_AUTHOR
Message: $COMMIT_MESSAGE
EOF

else
    echo ""
    echo "○ No changes detected - Skipping build"
    echo "  Current SHA: $LATEST_SHA"
    echo ""

    echo "UPSTREAM_CHANGED=false" > "$BUILD_FLAGS_FILE"
fi

# Always exit successfully (let pipeline decide)
exit 0
