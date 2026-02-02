#!/bin/bash
# Play thinking sounds (e.g., dial-up then Jeopardy)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_1=$("$SCRIPT_DIR/get-sound.sh" thinking 0 2>/dev/null)
SOUND_2=$("$SCRIPT_DIR/get-sound.sh" thinking 1 2>/dev/null)
PID_FILE="/tmp/claude-nostalgia-thinking.pid"

command -v afplay &>/dev/null || exit 0

# Kill any existing thinking sounds (subshell + afplay)
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        # Kill the subshell and all its children
        pkill -9 -P "$OLD_PID" 2>/dev/null || true
        kill -9 "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

# Also kill any stray afplay processes from this plugin
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

# Play sounds in sequence in background
(
    [ -n "$SOUND_1" ] && [ -f "$SOUND_1" ] && afplay "$SOUND_1" 2>/dev/null
    [ -n "$SOUND_2" ] && [ -f "$SOUND_2" ] && afplay "$SOUND_2" 2>/dev/null
    rm -f "$PID_FILE"
) &
echo $! > "$PID_FILE"

exit 0
