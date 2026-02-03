#!/bin/bash
# Toggle random mode on/off
# Usage: toggle-random.sh [on|off]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# User settings stored separately (not checked into git)
USER_SETTINGS_DIR="$HOME/.config/nostalgia-sounds"
USER_SETTINGS_FILE="$USER_SETTINGS_DIR/settings.json"

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Ensure user settings directory exists
mkdir -p "$USER_SETTINGS_DIR"

# Initialize user settings if doesn't exist
if [ ! -f "$USER_SETTINGS_FILE" ]; then
    echo '{}' > "$USER_SETTINGS_FILE"
fi

# Get current state (check user settings first, then config defaults)
CURRENT=$(jq -r '.randomMode // empty' "$USER_SETTINGS_FILE" 2>/dev/null)
if [ -z "$CURRENT" ] || [ "$CURRENT" = "null" ]; then
    CURRENT=$(jq -r '.randomMode // false' "$CONFIG_FILE" 2>/dev/null)
fi

# Determine new state
if [ "$1" = "on" ]; then
    NEW_STATE="true"
elif [ "$1" = "off" ]; then
    NEW_STATE="false"
elif [ -z "$1" ]; then
    # Toggle
    if [ "$CURRENT" = "true" ]; then
        NEW_STATE="false"
    else
        NEW_STATE="true"
    fi
else
    echo "Usage: toggle-random.sh [on|off]"
    echo "  on   - Enable random mode"
    echo "  off  - Disable random mode"
    echo "  (no args) - Toggle current state"
    exit 1
fi

# Update user settings (not plugin config)
TEMP_FILE=$(mktemp)
jq --argjson state "$NEW_STATE" '.randomMode = $state' "$USER_SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USER_SETTINGS_FILE"

if [ "$NEW_STATE" = "true" ]; then
    echo "Random mode enabled - sounds will be randomized by category"
else
    echo "Random mode disabled - using sound pack settings"
fi
echo "(Setting saved to $USER_SETTINGS_FILE)"
