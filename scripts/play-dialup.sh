#!/bin/bash
# Play dial-up modem tone then Jeopardy thinking music
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

command -v afplay &>/dev/null || exit 0

# Kill any existing nostalgia sounds
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

# Play dialup then jeopardy in background
(
    [ -f "$SOUNDS_DIR/dialup.mp3" ] && afplay "$SOUNDS_DIR/dialup.mp3" 2>/dev/null
    [ -f "$SOUNDS_DIR/jeopardy_think_real.mp3" ] && afplay "$SOUNDS_DIR/jeopardy_think_real.mp3" 2>/dev/null
) &

exit 0
