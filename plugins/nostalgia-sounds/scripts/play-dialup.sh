#!/bin/bash
# Play thinking sounds (e.g., dial-up then looping Jeopardy/jazz)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
PID_FILE="/tmp/claude-nostalgia-thinking.pid"
STOP_FILE="/tmp/claude-nostalgia-stop"
MAX_DURATION=600  # Safety timeout: 10 minutes max

command -v afplay &>/dev/null || exit 0

# Check if random mode is enabled
RANDOM_MODE="false"
if command -v jq &>/dev/null && [ -f "$CONFIG_FILE" ]; then
    RANDOM_MODE=$(jq -r '.randomMode // false' "$CONFIG_FILE")
fi

# Kill any existing thinking sounds (subshell + afplay)
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        pkill -9 -P "$OLD_PID" 2>/dev/null || true
        kill -9 "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

# Also kill any stray afplay processes from this plugin
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

# Clear any previous stop flag
rm -f "$STOP_FILE"

# Get initial sounds
SOUND_1=$("$SCRIPT_DIR/get-sound.sh" thinking 0 2>/dev/null)
SOUND_2=$("$SCRIPT_DIR/get-sound.sh" thinking 1 2>/dev/null)

# Play dialup then loop thinking music until stopped
(
    START_TIME=$(date +%s)

    # Play initial "connecting" sound
    [ -n "$SOUND_1" ] && [ -f "$SOUND_1" ] && afplay "$SOUND_1" 2>/dev/null

    # Loop thinking music until stop flag is set or timeout
    while true; do
        # Check for stop flag
        [ -f "$STOP_FILE" ] && break

        # Safety timeout check
        ELAPSED=$(( $(date +%s) - START_TIME ))
        [ $ELAPSED -ge $MAX_DURATION ] && break

        # In random mode, get a fresh random sound each loop
        if [ "$RANDOM_MODE" = "true" ]; then
            SOUND_2=$("$SCRIPT_DIR/get-sound.sh" thinking 1 2>/dev/null)
        fi

        # Play thinking loop sound
        [ -n "$SOUND_2" ] && [ -f "$SOUND_2" ] && afplay "$SOUND_2" 2>/dev/null
    done

    rm -f "$PID_FILE"
) &
echo $! > "$PID_FILE"

exit 0
