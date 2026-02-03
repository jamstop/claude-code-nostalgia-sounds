#!/bin/bash
# Play done sound when Claude finishes responding
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" done 2>/dev/null)
PID_FILE="/tmp/claude-nostalgia-thinking.pid"
STOP_FILE="/tmp/claude-nostalgia-stop"

command -v afplay &>/dev/null || exit 0

# Source helper functions
source "$SCRIPT_DIR/audio-cmd.sh" 2>/dev/null

# Set stop flag to break the loop
touch "$STOP_FILE"

# Try audio manager first
if manager_running; then
    send_cmd "stop"
    sleep 0.1
    [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && send_cmd "play" "$SOUND_FILE"
    rm -f "$PID_FILE"
    exit 0
fi

# Fallback: graceful kill
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ]; then
        # Kill children first (afplay), then parent
        for child in $(pgrep -P "$OLD_PID" 2>/dev/null); do
            graceful_kill "$child"
        done
        graceful_kill "$OLD_PID"
    fi
    rm -f "$PID_FILE"
fi

# Graceful kill any stray afplay from this plugin
for pid in $(pgrep -f "afplay.*nostalgia-sounds" 2>/dev/null); do
    graceful_kill "$pid"
done

# Small delay to ensure audio device is released
sleep 0.1

[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
