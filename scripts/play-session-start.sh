#!/bin/bash
set -eu
# Play Windows XP startup sound when session starts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="$SCRIPT_DIR/../sounds/winxp_startup.mp3"

command -v afplay &>/dev/null || exit 0
[ -f "$SOUND_FILE" ] && (afplay "$SOUND_FILE" &>/dev/null &)
exit 0
