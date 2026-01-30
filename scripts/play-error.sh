#!/bin/bash
set -eu
# Play error sound on tool failures
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="$SCRIPT_DIR/../sounds/error.wav"

command -v afplay &>/dev/null || exit 0
[ -f "$SOUND_FILE" ] && afplay "$SOUND_FILE" &>/dev/null &
exit 0
