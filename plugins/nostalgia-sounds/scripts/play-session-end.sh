#!/bin/bash
# Play shutdown sound when session ends and stop audio manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" shutdown 2>/dev/null)
PIPE_FILE="/tmp/claude-nostalgia-audio.pipe"
MANAGER_PID_FILE="/tmp/claude-nostalgia-manager.pid"

command -v afplay &>/dev/null || exit 0

# Stop audio manager gracefully
if [ -p "$PIPE_FILE" ]; then
    echo "quit" > "$PIPE_FILE" &
    sleep 0.1
fi

# Cleanup if manager didn't stop
if [ -f "$MANAGER_PID_FILE" ]; then
    PID=$(cat "$MANAGER_PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -TERM "$PID" 2>/dev/null
        sleep 0.1
        kill -9 "$PID" 2>/dev/null
    fi
    rm -f "$MANAGER_PID_FILE"
fi
rm -f "$PIPE_FILE"

# Play shutdown sound
[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
