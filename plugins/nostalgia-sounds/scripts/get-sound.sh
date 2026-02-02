#!/bin/bash
# Get sound file path for an event from the active pack
# Usage: get-sound.sh <event> [index]
# Events: startup, shutdown, thinking, done, notification
# Index is optional, used for arrays like "thinking" (0 = first, 1 = second, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

EVENT="${1:-}"
INDEX="${2:-0}"

if [ -z "$EVENT" ]; then
    echo "Usage: get-sound.sh <event> [index]" >&2
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    # Fallback to defaults if jq not available
    case "$EVENT" in
        startup) echo "$SOUNDS_DIR/winxp_startup.mp3" ;;
        shutdown) echo "$SOUNDS_DIR/winxp_shutdown.mp3" ;;
        thinking)
            if [ "$INDEX" = "0" ]; then
                echo "$SOUNDS_DIR/dialup.mp3"
            else
                echo "$SOUNDS_DIR/jeopardy_think_real.mp3"
            fi
            ;;
        done) echo "$SOUNDS_DIR/youve_got_mail.mp3" ;;
        notification) echo "$SOUNDS_DIR/youve_got_mail.mp3" ;;
    esac
    exit 0
fi

# Check if random mode is enabled
RANDOM_MODE=$(jq -r '.randomMode // false' "$CONFIG_FILE")

if [ "$RANDOM_MODE" = "true" ]; then
    # Random mode: pick from category
    CATEGORY="$EVENT"

    # Map thinking index to category
    if [ "$EVENT" = "thinking" ]; then
        if [ "$INDEX" = "0" ]; then
            CATEGORY="thinking"
        else
            CATEGORY="thinkingLoop"
        fi
    fi

    # Get sounds array for category
    SOUNDS_JSON=$(jq -r --arg cat "$CATEGORY" '.soundCategories[$cat] // []' "$CONFIG_FILE")
    COUNT=$(echo "$SOUNDS_JSON" | jq 'length')

    if [ "$COUNT" -gt 0 ]; then
        # Use bash RANDOM for proper randomization
        RAND_INDEX=$((RANDOM % COUNT))
        SOUND=$(echo "$SOUNDS_JSON" | jq -r ".[$RAND_INDEX]")

        if [ -n "$SOUND" ] && [ "$SOUND" != "null" ]; then
            echo "$SOUNDS_DIR/$SOUND"
            exit 0
        fi
    fi
    # Fall through to pack-based lookup if category not found
fi

# Get active pack
ACTIVE_PACK=$(jq -r '.activePack // "default"' "$CONFIG_FILE")

# Get sound for event
SOUND=$(jq -r --arg pack "$ACTIVE_PACK" --arg event "$EVENT" --argjson idx "$INDEX" '
    .packs[$pack].sounds[$event] // .packs["default"].sounds[$event] |
    if type == "array" then .[$idx] // .[0]
    else .
    end
' "$CONFIG_FILE")

if [ -n "$SOUND" ] && [ "$SOUND" != "null" ]; then
    echo "$SOUNDS_DIR/$SOUND"
else
    exit 1
fi
