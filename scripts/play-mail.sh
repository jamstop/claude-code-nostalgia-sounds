#!/bin/bash
set -eu
# Play "You've Got Mail" on notifications
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="$SCRIPT_DIR/../sounds/youve_got_mail.mp3"

command -v afplay &>/dev/null || exit 0
[ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
