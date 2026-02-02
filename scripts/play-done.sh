#!/bin/bash
# Play "You've Got Mail" when Claude finishes responding
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="$SCRIPT_DIR/../sounds/youve_got_mail.mp3"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

command -v afplay &>/dev/null || exit 0

# Kill any playing sounds first (dialup/jeopardy)
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

[ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
