#!/bin/bash
# Change the active sound pack
# Usage: set-pack.sh <pack-name>
# Run without arguments to list available packs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Available sound packs:"
    echo ""
    ACTIVE=$(jq -r '.activePack' "$CONFIG_FILE")
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

# Update active pack
jq --arg pack "$PACK" '.activePack = $pack' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

PACK_NAME=$(jq -r ".packs[\"$PACK\"].name" "$CONFIG_FILE")
echo "Switched to: $PACK_NAME"
echo ""
echo "Sounds:"
jq -r ".packs[\"$PACK\"].sounds | to_entries[] | \"  \(.key): \(.value)\"" "$CONFIG_FILE"
