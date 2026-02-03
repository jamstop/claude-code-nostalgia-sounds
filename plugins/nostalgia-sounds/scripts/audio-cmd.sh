#!/bin/bash
# Send command to audio manager (or fall back to direct control)

PIPE_FILE="/tmp/claude-nostalgia-audio.pipe"
MANAGER_PID_FILE="/tmp/claude-nostalgia-manager.pid"

# Check if audio manager is running
manager_running() {
    if [ -f "$MANAGER_PID_FILE" ]; then
        local pid=$(cat "$MANAGER_PID_FILE" 2>/dev/null)
        [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
    fi
    return 1
}

# Send command to manager
send_cmd() {
    if [ -p "$PIPE_FILE" ]; then
        echo "$@" > "$PIPE_FILE" &
        return 0
    fi
    return 1
}

# Graceful kill helper (for fallback mode)
graceful_kill() {
    local pid="$1"
    [ -z "$pid" ] && return

    # Try SIGTERM first
    kill -TERM "$pid" 2>/dev/null

    # Wait up to 250ms for graceful shutdown
    for i in 1 2 3 4 5; do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 0.05
    done

    # Force kill if still running
    kill -9 "$pid" 2>/dev/null
}

# Export for use by other scripts
export -f manager_running send_cmd graceful_kill
export PIPE_FILE MANAGER_PID_FILE
