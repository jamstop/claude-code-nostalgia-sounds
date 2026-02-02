#!/bin/bash
# Play done sound when Claude finishes responding
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" done 2>/dev/null)

command -v afplay &>/dev/null || exit 0

# Kill any playing sounds first (dialup/jeopardy)
pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null || true

[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
