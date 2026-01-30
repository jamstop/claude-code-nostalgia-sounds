#!/bin/bash
set -eu
# Play dial-up modem tone then Jeopardy thinking music when Claude starts processing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIALUP_FILE="$SCRIPT_DIR/../sounds/dialup.mp3"
JEOPARDY_FILE="$SCRIPT_DIR/../sounds/jeopardy_think_real.mp3"
PID_FILE="/tmp/claude-nostalgia-sound.pid"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

command -v afplay &>/dev/null || exit 0

# Kill any existing sound playback first to prevent overlap
if [ -f "$PID_FILE" ]; then
    OLD_PIDS=$(cat "$PID_FILE" 2>/dev/null || true)
    for pid in $OLD_PIDS; do
        kill -9 "$pid" 2>/dev/null || true
    done
    rm -f "$PID_FILE"
fi

# Also kill by pattern (more reliable) - only match our sounds directory
pkill -9 -f "afplay.*${SOUNDS_DIR}/" 2>/dev/null || true

# Small delay to ensure kills complete
sleep 0.05

# Play dialup then jeopardy, tracking all PIDs
: > "$PID_FILE"  # Create/truncate PID file

(
    if [ -f "$DIALUP_FILE" ]; then
        afplay "$DIALUP_FILE" 2>/dev/null &
        echo $! >> "$PID_FILE"
        wait $!
    fi
    if [ -f "$JEOPARDY_FILE" ]; then
        afplay "$JEOPARDY_FILE" 2>/dev/null &
        echo $! >> "$PID_FILE"
        wait $!
    fi
) &
echo $! >> "$PID_FILE"

exit 0
