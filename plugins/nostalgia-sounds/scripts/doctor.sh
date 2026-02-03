#!/bin/bash
# Check plugin dependencies and configuration
# Usage: doctor.sh

echo "=== Nostalgia Sounds Plugin - Health Check ==="
echo ""

# Colors (if terminal supports them)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

ISSUES=0

echo "Dependencies:"
echo ""

# Required: afplay
if command -v afplay &>/dev/null; then
    pass "afplay (required) - $(which afplay)"
else
    fail "afplay (required) - NOT FOUND"
    echo "    afplay is built into macOS. If missing, this plugin won't work."
    ISSUES=$((ISSUES + 1))
fi

# Required: jq
if command -v jq &>/dev/null; then
    pass "jq (required) - $(which jq)"
else
    fail "jq (required) - NOT FOUND"
    echo "    Install with: brew install jq"
    ISSUES=$((ISSUES + 1))
fi

# Optional: sox
if command -v sox &>/dev/null && command -v play &>/dev/null; then
    pass "sox (optional) - $(which sox)"
    echo "    Crossfading enabled"
else
    warn "sox (optional) - not installed"
    echo "    For smooth crossfading between sounds: brew install sox"
fi

# Optional: ffmpeg
if command -v ffmpeg &>/dev/null; then
    pass "ffmpeg (optional) - $(which ffmpeg)"
else
    warn "ffmpeg (optional) - not installed"
    echo "    For normalizing sound volumes: brew install ffmpeg"
fi

echo ""
echo "Configuration:"
echo ""

# Check user settings
USER_SETTINGS="$HOME/.config/nostalgia-sounds/settings.json"
if [ -f "$USER_SETTINGS" ]; then
    pass "User settings - $USER_SETTINGS"
    if command -v jq &>/dev/null; then
        RANDOM_MODE=$(jq -r '.randomMode // "not set"' "$USER_SETTINGS" 2>/dev/null)
        ACTIVE_PACK=$(jq -r '.activePack // "not set"' "$USER_SETTINGS" 2>/dev/null)
        echo "    randomMode: $RANDOM_MODE"
        echo "    activePack: $ACTIVE_PACK"
    fi
else
    warn "User settings - not created yet"
    echo "    Will be created when you first change settings"
    echo "    Default settings from config.json will be used"
fi

# Check plugin config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
if [ -f "$CONFIG_FILE" ]; then
    pass "Plugin config - $CONFIG_FILE"
else
    fail "Plugin config - NOT FOUND at $CONFIG_FILE"
    ISSUES=$((ISSUES + 1))
fi

# Check sounds directory
SOUNDS_DIR="$SCRIPT_DIR/../sounds"
if [ -d "$SOUNDS_DIR" ]; then
    SOUND_COUNT=$(ls -1 "$SOUNDS_DIR" | wc -l | tr -d ' ')
    pass "Sounds directory - $SOUND_COUNT files"
else
    fail "Sounds directory - NOT FOUND at $SOUNDS_DIR"
    ISSUES=$((ISSUES + 1))
fi

echo ""
echo "Audio Manager:"
echo ""

# Check if audio manager is running
MANAGER_PID_FILE="/tmp/claude-nostalgia-manager.pid"
if [ -f "$MANAGER_PID_FILE" ]; then
    MANAGER_PID=$(cat "$MANAGER_PID_FILE" 2>/dev/null)
    if [ -n "$MANAGER_PID" ] && kill -0 "$MANAGER_PID" 2>/dev/null; then
        pass "Audio manager - running (PID $MANAGER_PID)"
    else
        warn "Audio manager - stale PID file (not running)"
        echo "    Will start automatically on next session"
    fi
else
    warn "Audio manager - not running"
    echo "    Will start automatically on next session"
fi

# Check for stray processes
STRAY_COUNT=$(pgrep -f "afplay.*nostalgia-sounds" 2>/dev/null | wc -l | tr -d ' ')
if [ "$STRAY_COUNT" -gt 0 ]; then
    warn "Stray afplay processes: $STRAY_COUNT"
    echo "    Run: pkill -f 'afplay.*nostalgia-sounds'"
fi

echo ""
echo "Version Check:"
echo ""

# Get current version from plugin.json
PLUGIN_JSON="$SCRIPT_DIR/../.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ] && command -v jq &>/dev/null; then
    CURRENT_VERSION=$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null)
    echo "    Installed: $CURRENT_VERSION"

    # Check latest version from GitHub (with timeout)
    LATEST_VERSION=$(curl -s --max-time 5 \
        "https://raw.githubusercontent.com/jamstop/claude-code-nostalgia-sounds/main/plugins/nostalgia-sounds/.claude-plugin/plugin.json" \
        2>/dev/null | jq -r '.version' 2>/dev/null)

    if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "null" ]; then
        echo "    Latest:    $LATEST_VERSION"
        if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
            warn "Update available: $CURRENT_VERSION → $LATEST_VERSION"
            echo "    Run: /plugin marketplace update nostalgia-sounds-marketplace"
        else
            pass "You're on the latest version"
        fi
    else
        warn "Could not check for updates (network issue?)"
    fi
else
    warn "Could not determine current version"
fi

echo ""
echo "---"
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}All required dependencies OK!${NC}"
else
    echo -e "${RED}$ISSUES issue(s) found.${NC} Please fix before using the plugin."
fi
echo ""
