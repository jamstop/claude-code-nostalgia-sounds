#!/bin/bash
# Change the active sound pack
# Usage: set-pack.sh <pack-name>
# Run without arguments to list available packs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# User settings stored separately (not checked into git)
USER_SETTINGS_DIR="$HOME/.config/nostalgia-sounds"
USER_SETTINGS_FILE="$USER_SETTINGS_DIR/settings.json"

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq" >&2
    exit 1
fi

# Ensure user settings directory exists
mkdir -p "$USER_SETTINGS_DIR"

# Initialize user settings if doesn't exist
if [ ! -f "$USER_SETTINGS_FILE" ]; then
    echo '{}' > "$USER_SETTINGS_FILE"
fi

# Get current active pack (check user settings first)
get_active_pack() {
    local active=$(jq -r '.activePack // empty' "$USER_SETTINGS_FILE" 2>/dev/null)
    if [ -z "$active" ] || [ "$active" = "null" ]; then
        active=$(jq -r '.activePack // "default"' "$CONFIG_FILE" 2>/dev/null)
    fi
    echo "$active"
}

if [ -z "$1" ]; then
    echo "Available sound packs:"
    echo ""
    ACTIVE=$(get_active_pack)
    jq -r '.packs | to_entries[] | "\(.key): \(.value.name) - \(.value.description)"' "$CONFIG_FILE" | while read -r line; do
        pack=$(echo "$line" | cut -d: -f1)
        if [ "$pack" = "$ACTIVE" ]; then
            echo "  * $line"
        else
            echo "    $line"
        fi
    done
    echo ""
    echo "Current pack: $ACTIVE"
    echo ""
    echo "Usage: $0 <pack-name>"
    exit 0
fi

PACK="$1"

# Check if pack exists
if ! jq -e ".packs[\"$PACK\"]" "$CONFIG_FILE" &>/dev/null; then
    echo "Error: Pack '$PACK' not found." >&2
    echo "Available packs: $(jq -r '.packs | keys | join(", ")' "$CONFIG_FILE")" >&2
    exit 1
fi

# Update user settings (not plugin config)
TEMP_FILE=$(mktemp)
jq --arg pack "$PACK" '.activePack = $pack' "$USER_SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$USER_SETTINGS_FILE"

PACK_NAME=$(jq -r ".packs[\"$PACK\"].name" "$CONFIG_FILE")
echo "Switched to: $PACK_NAME"
echo ""
echo "Sounds:"
jq -r ".packs[\"$PACK\"].sounds | to_entries[] | \"  \(.key): \(.value)\"" "$CONFIG_FILE"
echo ""
echo "(Setting saved to $USER_SETTINGS_FILE)"
