#!/bin/bash
# Stop thinking sounds (without playing done sound)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="/tmp/claude-nostalgia-thinking.pid"
STOP_FILE="/tmp/claude-nostalgia-stop"

# Source helper functions
source "$SCRIPT_DIR/audio-cmd.sh" 2>/dev/null

# Set stop flag to break the loop
touch "$STOP_FILE"

# Try audio manager first
if manager_running && send_cmd "stop"; then
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

exit 0
