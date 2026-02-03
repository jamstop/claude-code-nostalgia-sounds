#!/bin/bash
# Play thinking sounds (e.g., dial-up then looping Jeopardy/jazz)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
PID_FILE="/tmp/claude-nostalgia-thinking.pid"
STOP_FILE="/tmp/claude-nostalgia-stop"
MAX_DURATION=600  # Safety timeout: 10 minutes max

command -v afplay &>/dev/null || exit 0

# Source helper functions
source "$SCRIPT_DIR/audio-cmd.sh" 2>/dev/null

# User settings stored separately (not checked into git)
USER_SETTINGS_FILE="$HOME/.config/nostalgia-sounds/settings.json"

# Check if random mode is enabled (user settings first, then config defaults)
RANDOM_MODE=""
if command -v jq &>/dev/null; then
    # Check user settings first
    if [ -f "$USER_SETTINGS_FILE" ]; then
        USER_RANDOM=$(jq -r '.randomMode // empty' "$USER_SETTINGS_FILE" 2>/dev/null)
        if [ -n "$USER_RANDOM" ] && [ "$USER_RANDOM" != "null" ]; then
            RANDOM_MODE="$USER_RANDOM"
        fi
    fi
    # Fall back to config.json default if not set in user settings
    if [ -z "$RANDOM_MODE" ] && [ -f "$CONFIG_FILE" ]; then
        RANDOM_MODE=$(jq -r '.randomMode // false' "$CONFIG_FILE")
    fi
fi
# Default to false if still not set
[ -z "$RANDOM_MODE" ] && RANDOM_MODE="false"

# Graceful cleanup of existing sounds
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        # Kill children first (afplay), then parent
        for child in $(pgrep -P "$OLD_PID" 2>/dev/null); do
            graceful_kill "$child" 2>/dev/null
        done
        graceful_kill "$OLD_PID" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

# Graceful kill any stray afplay from this plugin
for pid in $(pgrep -f "afplay.*nostalgia-sounds" 2>/dev/null); do
    graceful_kill "$pid" 2>/dev/null
done

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
