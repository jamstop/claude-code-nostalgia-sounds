#!/bin/bash
# Update nostalgia-sounds plugin and clear cache
# Usage: update.sh

echo "=== Nostalgia Sounds - Update ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

CACHE_DIR="$HOME/.claude/plugins/cache/nostalgia-sounds-marketplace"
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/nostalgia-sounds-marketplace"

# Get current installed version
CURRENT_VERSION="unknown"
if [ -d "$CACHE_DIR" ]; then
    CURRENT_VERSION=$(ls -1 "$CACHE_DIR/nostalgia-sounds" 2>/dev/null | sort -V | tail -1)
fi
echo "Installed version: $CURRENT_VERSION"

# Check latest version from GitHub
echo -n "Checking latest version... "
LATEST_VERSION=$(curl -s --max-time 5 \
    "https://raw.githubusercontent.com/jamstop/claude-code-nostalgia-sounds/main/plugins/nostalgia-sounds/.claude-plugin/plugin.json" \
    2>/dev/null | jq -r '.version' 2>/dev/null)

if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "null" ]; then
    echo "$LATEST_VERSION"
else
    echo -e "${RED}failed to fetch${NC}"
    echo "Check your network connection."
    exit 1
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}You're already on the latest version!${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Update available: $CURRENT_VERSION → $LATEST_VERSION${NC}"
echo ""

# Clear cache
echo -n "Clearing plugin cache... "
if [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
    echo -e "${GREEN}done${NC}"
else
    echo "no cache found"
fi

# Update marketplace
echo -n "Updating marketplace... "
if [ -d "$MARKETPLACE_DIR" ]; then
    cd "$MARKETPLACE_DIR" && git fetch origin main && git reset --hard origin/main >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}done${NC}"
    else
        echo -e "${RED}failed${NC}"
        echo "Try: /plugin marketplace update nostalgia-sounds-marketplace"
    fi
else
    echo "marketplace not found"
    echo "Install with: /plugin marketplace add jamstop/claude-code-nostalgia-sounds"
    exit 1
fi

echo ""
echo -e "${GREEN}Update complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run the doctor script to verify: doctor.sh"
echo ""
