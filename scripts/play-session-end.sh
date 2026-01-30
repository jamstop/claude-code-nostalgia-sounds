#!/bin/bash
set -eu
# Play Windows XP shutdown sound when session ends
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="$SCRIPT_DIR/../sounds/winxp_shutdown.mp3"

command -v afplay &>/dev/null || exit 0
[ -f "$SOUND_FILE" ] && (afplay "$SOUND_FILE" &>/dev/null &)
exit 0
