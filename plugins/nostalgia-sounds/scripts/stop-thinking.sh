#!/bin/bash
# Stop thinking sounds (without playing done sound)
PID_FILE="/tmp/claude-nostalgia-thinking.pid"

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

exit 0
