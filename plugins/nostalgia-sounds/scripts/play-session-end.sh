#!/bin/bash
# Play shutdown sound when session ends and clean up ALL audio processes
# This is critical for cleanup since hooks don't always fire reliably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" shutdown 2>/dev/null)
PIPE_FILE="/tmp/claude-nostalgia-audio.pipe"
MANAGER_PID_FILE="/tmp/claude-nostalgia-manager.pid"
THINKING_PID_FILE="/tmp/claude-nostalgia-thinking.pid"
STOP_FILE="/tmp/claude-nostalgia-stop"

command -v afplay &>/dev/null || exit 0

# === AGGRESSIVE CLEANUP ===
# Set stop flag first to signal any running loops
touch "$STOP_FILE"

# Kill thinking loop process and its children (afplay)
if [ -f "$THINKING_PID_FILE" ]; then
    PID=$(cat "$THINKING_PID_FILE" 2>/dev/null)
    if [ -n "$PID" ]; then
        # Kill children first (afplay processes)
        for child in $(pgrep -P "$PID" 2>/dev/null); do
            kill -TERM "$child" 2>/dev/null
        done
        # Then kill the parent loop
        kill -TERM "$PID" 2>/dev/null
        sleep 0.05
        kill -9 "$PID" 2>/dev/null
    fi
    rm -f "$THINKING_PID_FILE"
fi

# Kill any stray afplay processes from this plugin (belt and suspenders)
pkill -f "afplay.*nostalgia-sounds" 2>/dev/null

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

# Clean up all temp files
rm -f "$PIPE_FILE" "$STOP_FILE"

# Play shutdown sound (disown to survive parent exit)
if [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ]; then
    afplay "$SOUND_FILE" &>/dev/null &
    disown 2>/dev/null
fi
exit 0
