#!/bin/bash
# Play notification sound
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE=$("$SCRIPT_DIR/get-sound.sh" notification 2>/dev/null)

command -v afplay &>/dev/null || exit 0
[ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
