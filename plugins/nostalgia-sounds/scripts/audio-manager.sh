#!/bin/bash
# Long-running audio manager for nostalgia-sounds
# Communicates via named pipe to avoid constant process spawning/killing
# Supports sox crossfading when available

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
PIPE_FILE="/tmp/claude-nostalgia-audio.pipe"
PID_FILE="/tmp/claude-nostalgia-manager.pid"
AUDIO_PID=""
USE_SOX="false"
CROSSFADE_DURATION="0.5"

command -v afplay &>/dev/null || exit 0

# Check for sox (with homebrew hint)
check_sox() {
    if command -v sox &>/dev/null && command -v play &>/dev/null; then
        USE_SOX="true"
        echo "Sox available - crossfading enabled"
    else
        echo "Sox not found. For crossfading: brew install sox"
        echo "Falling back to afplay"
    fi
}

# Gracefully stop current audio
stop_audio() {
    if [ -n "$AUDIO_PID" ] && kill -0 "$AUDIO_PID" 2>/dev/null; then
        # Graceful SIGTERM first
        kill -TERM "$AUDIO_PID" 2>/dev/null

        # Wait briefly for graceful shutdown
        for i in 1 2 3 4 5; do
            kill -0 "$AUDIO_PID" 2>/dev/null || break
            sleep 0.05
        done

        # Force kill only if still running
        if kill -0 "$AUDIO_PID" 2>/dev/null; then
            kill -9 "$AUDIO_PID" 2>/dev/null
        fi

        wait "$AUDIO_PID" 2>/dev/null
        AUDIO_PID=""
    fi
}

# Play a sound file with optional crossfade
play_sound() {
    local sound_file="$1"
    local loop="$2"

    [ ! -f "$sound_file" ] && return

    if [ "$USE_SOX" = "true" ] && [ "$loop" != "loop" ]; then
        # Use sox play with fade for non-looping sounds
        stop_audio
        play -q "$sound_file" fade t 0 0 "$CROSSFADE_DURATION" 2>/dev/null &
        AUDIO_PID=$!
    elif [ "$USE_SOX" = "true" ] && [ "$loop" = "loop" ]; then
        # Sox looping with crossfade
        stop_audio
        (
            while true; do
                # Play with fade out at end, fade in at start
                play -q "$sound_file" fade t "$CROSSFADE_DURATION" 0 "$CROSSFADE_DURATION" 2>/dev/null || break
            done
        ) &
        AUDIO_PID=$!
    else
        # Fallback to afplay
        stop_audio
        if [ "$loop" = "loop" ]; then
            (
                while true; do
                    afplay "$sound_file" 2>/dev/null || break
                done
            ) &
            AUDIO_PID=$!
        else
            afplay "$sound_file" 2>/dev/null &
            AUDIO_PID=$!
        fi
    fi
}

# Cleanup on exit
cleanup() {
    stop_audio
    rm -f "$PIPE_FILE" "$PID_FILE"
    exit 0
}

trap cleanup EXIT SIGTERM SIGINT

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Audio manager already running (PID $OLD_PID)"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Check for sox
check_sox

# Create named pipe
rm -f "$PIPE_FILE"
mkfifo "$PIPE_FILE"
echo $$ > "$PID_FILE"

echo "Audio manager started (PID $$)"

# Main loop - read commands from pipe
while true; do
    if read -r cmd args < "$PIPE_FILE"; then
        case "$cmd" in
            play)
                play_sound "$args"
                ;;
            play_loop)
                play_sound "$args" "loop"
                ;;
            crossfade)
                # Crossfade to new sound (sox only)
                if [ "$USE_SOX" = "true" ]; then
                    # Current sound fades out while new one fades in
                    # This is a simplified version - true crossfade would need mixing
                    play_sound "$args"
                else
                    play_sound "$args"
                fi
                ;;
            stop)
                stop_audio
                ;;
            quit)
                cleanup
                ;;
            status)
                if [ -n "$AUDIO_PID" ] && kill -0 "$AUDIO_PID" 2>/dev/null; then
                    echo "Playing (PID $AUDIO_PID)"
                else
                    echo "Idle"
                fi
                ;;
            *)
                echo "Unknown command: $cmd"
                ;;
        esac
    fi
done
