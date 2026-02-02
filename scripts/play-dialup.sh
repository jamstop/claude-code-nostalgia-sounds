#!/bin/bash
# Play thinking sounds (e.g., dial-up then Jeopardy)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_1=$("$SCRIPT_DIR/get-sound.sh" thinking 0 2>/dev/null)
SOUND_2=$("$SCRIPT_DIR/get-sound.sh" thinking 1 2>/dev/null)

command -v afplay &>/dev/null || exit 0

# Kill any existing nostalgia sounds
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

# Play sounds in sequence in background
(
    [ -n "$SOUND_1" ] && [ -f "$SOUND_1" ] && afplay "$SOUND_1" 2>/dev/null
    [ -n "$SOUND_2" ] && [ -f "$SOUND_2" ] && afplay "$SOUND_2" 2>/dev/null
) &

exit 0
