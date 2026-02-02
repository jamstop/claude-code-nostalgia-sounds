#!/bin/bash
# Toggle random mode on/off
# Usage: toggle-random.sh [on|off]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Get current state
CURRENT=$(jq -r '.randomMode // false' "$CONFIG_FILE")

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

# Update config
TEMP_FILE=$(mktemp)
jq --argjson state "$NEW_STATE" '.randomMode = $state' "$CONFIG_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$CONFIG_FILE"

if [ "$NEW_STATE" = "true" ]; then
    echo "Random mode enabled - sounds will be randomized by category"
else
    echo "Random mode disabled - using sound pack settings"
fi
