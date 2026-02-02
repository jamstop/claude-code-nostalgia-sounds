#!/bin/bash
# Play notification sound
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" notification 2>/dev/null)
PID_FILE="/tmp/claude-nostalgia-thinking.pid"

command -v afplay &>/dev/null || exit 0

# Kill thinking sounds (subshell + afplay)
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        pkill -9 -P "$OLD_PID" 2>/dev/null || true
        kill -9 "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

# Small delay to ensure kills complete
sleep 0.05

[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
