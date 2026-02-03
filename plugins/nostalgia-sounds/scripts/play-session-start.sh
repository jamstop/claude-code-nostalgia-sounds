#!/bin/bash
# Play startup sound when session starts and launch audio manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" startup 2>/dev/null)
MANAGER_PID_FILE="/tmp/claude-nostalgia-manager.pid"

command -v afplay &>/dev/null || exit 0

# Start audio manager if not already running
if [ -f "$MANAGER_PID_FILE" ]; then
    OLD_PID=$(cat "$MANAGER_PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && ! kill -0 "$OLD_PID" 2>/dev/null; then
        rm -f "$MANAGER_PID_FILE"
    fi
fi

if [ ! -f "$MANAGER_PID_FILE" ]; then
    "$SCRIPT_DIR/audio-manager.sh" &>/dev/null &
    disown 2>/dev/null
    sleep 0.2  # Give manager time to create pipe
fi

# Play startup sound
[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
