#!/bin/bash
# Play Windows XP shutdown sound when session ends
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHUTDOWN_FILE="$SCRIPT_DIR/../sounds/winxp_shutdown.mp3"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

# Kill any playing sounds first
pkill -9 -f "afplay.*${SOUNDS_DIR}/" 2>/dev/null || true

# Play synchronously - the hook waits for this to complete
[ -f "$SHUTDOWN_FILE" ] && afplay "$SHUTDOWN_FILE"

exit 0
