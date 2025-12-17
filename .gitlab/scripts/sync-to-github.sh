#!/bin/bash
# Sync GitLab repository to GitHub mirror
# Supports excluding files via .gitlab/github-exclude.txt

set -e

GITHUB_REMOTE="git@github.com:bd5rv/aprsc-docker.git"
EXCLUDE_FILE=".gitlab/github-exclude.txt"

echo "=========================================="
echo "Syncing to GitHub Mirror"
echo "=========================================="
echo ""

# Add GitHub remote if not exists
if ! git remote get-url github 2>/dev/null; then
    echo "Adding GitHub remote..."
    git remote add github "$GITHUB_REMOTE"
else
    echo "GitHub remote already exists"
    # Update URL in case it changed
    git remote set-url github "$GITHUB_REMOTE"
fi

# Fetch all branches and tags from origin (GitLab)
echo ""
echo "Fetching latest from GitLab..."
git fetch origin --prune --tags

# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
echo "Current branch: $CURRENT_BRANCH"

# Check for exclude file
EXCLUDE_PATTERNS=()
if [ -f "$EXCLUDE_FILE" ]; then
    echo ""
    echo "Loading exclusion patterns from $EXCLUDE_FILE..."

    # Read non-empty, non-comment lines
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            EXCLUDE_PATTERNS+=("$line")
            echo "  - Exclude: $line"
        fi
    done < "$EXCLUDE_FILE"
fi

# Decide sync strategy
if [ ${#EXCLUDE_PATTERNS[@]} -eq 0 ]; then
    echo ""
    echo "No exclusions configured - syncing all files"
    echo ""

    # Standard sync (all files)
    echo "Pushing all branches to GitHub..."
    if git push github --all --force; then
        echo "✓ Branches pushed successfully"
    else
        echo "✗ Failed to push branches"
        exit 1
    fi

    echo ""
    echo "Pushing all tags to GitHub..."
    if git push github --tags --force; then
        echo "✓ Tags pushed successfully"
    else
        echo "✗ Failed to push tags"
        exit 1
    fi

else
    echo ""
    echo "Exclusions configured - using filtered sync"
    echo ""

    # Create a temporary branch for GitHub sync
    TEMP_BRANCH="temp-github-sync-$$"

    # Checkout a new orphan branch based on current branch
    echo "Creating temporary branch: $TEMP_BRANCH"
    git checkout -b "$TEMP_BRANCH" "origin/$CURRENT_BRANCH"

    # Remove excluded files
    echo ""
    echo "Removing excluded files..."
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # Use git rm with --ignore-unmatch to avoid errors if file doesn't exist
        if git ls-files | grep -q "$pattern"; then
            git rm -r --ignore-unmatch "$pattern" || true
            echo "  ✓ Removed: $pattern"
        fi
    done

    # Commit changes if any files were removed
    if ! git diff --cached --quiet; then
        git commit -m "chore: Remove GitLab-only files for GitHub mirror

[skip ci]

Files excluded for GitHub sync (defined in $EXCLUDE_FILE):
$(printf '  - %s\n' "${EXCLUDE_PATTERNS[@]}")"
        echo "✓ Changes committed"
    else
        echo "○ No files to remove"
    fi

    # Push to GitHub
    echo ""
    echo "Pushing to GitHub..."
    if git push github "$TEMP_BRANCH:$CURRENT_BRANCH" --force; then
        echo "✓ Pushed successfully"
    else
        echo "✗ Failed to push"
        git checkout "$CURRENT_BRANCH"
        git branch -D "$TEMP_BRANCH"
        exit 1
    fi

    # Push tags
    echo ""
    echo "Pushing tags to GitHub..."
    git push github --tags --force || true

    # Return to original branch
    echo ""
    echo "Cleaning up..."
    git checkout "$CURRENT_BRANCH"
    git branch -D "$TEMP_BRANCH"
    echo "✓ Temporary branch deleted"
fi

# Verify sync
echo ""
echo "Verifying sync..."

# Get latest commit from GitLab
GITLAB_HEAD=$(git rev-parse "origin/$CURRENT_BRANCH")
echo "GitLab HEAD: $GITLAB_HEAD"

# Fetch from GitHub to verify
git fetch github "$CURRENT_BRANCH" 2>/dev/null || git fetch github main

# Get latest commit from GitHub
GITHUB_HEAD=$(git rev-parse "github/$CURRENT_BRANCH" 2>/dev/null || git rev-parse github/main)
echo "GitHub HEAD: $GITHUB_HEAD"

# Note: Heads will differ if exclusions are used, which is expected
if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
    echo ""
    echo "○ Sync with exclusions completed"
    echo "  Note: Commit SHAs differ because files were excluded"
elif [ "$GITLAB_HEAD" = "$GITHUB_HEAD" ]; then
    echo ""
    echo "✓ Sync successful!"
    echo "  Both repositories are at commit: ${GITLAB_HEAD:0:8}"
else
    echo ""
    echo "! Sync verification: commits differ"
    echo "  GitLab: $GITLAB_HEAD"
    echo "  GitHub: $GITHUB_HEAD"
    echo "  This may be normal if exclusions are used or branches diverged"
fi

echo ""
echo "=========================================="
echo "GitHub mirror updated successfully!"
echo "URL: https://github.com/bd5rv/aprsc-docker"
echo "=========================================="

exit 0
