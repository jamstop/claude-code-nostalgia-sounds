#!/bin/bash
# Setup script for nostalgia-sounds plugin
# Downloads classic Windows sounds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../sounds"

cd "$SOUNDS_DIR"

echo "Downloading classic sounds..."

# Dial-up modem (from a working source)
echo "Fetching dial-up modem sound..."
curl -sL "https://upload.wikimedia.org/wikipedia/commons/3/35/Dial_up_modem_noises.ogg" -o dialup.ogg
if [ -f dialup.ogg ] && [ $(stat -f%z dialup.ogg 2>/dev/null || stat -c%s dialup.ogg 2>/dev/null) -gt 1000 ]; then
    # Convert to mp3 if ffmpeg available
    if command -v ffmpeg &>/dev/null; then
        ffmpeg -y -i dialup.ogg -t 5 -q:a 2 dialup.mp3 2>/dev/null
        rm dialup.ogg
        echo "  - dialup.mp3 (5 second clip)"
    else
        mv dialup.ogg dialup.mp3
        echo "  - dialup.ogg (install ffmpeg to convert/trim)"
    fi
else
    echo "  - Failed to download dial-up sound"
fi

# For Windows sounds, you'll need to source them yourself
# Here are some options:

cat << 'EOF'

Windows sounds need to be added manually. Options:

1. Copy from a Windows machine:
   - C:\Windows\Media\tada.wav -> sounds/tada.wav
   - C:\Windows\Media\chord.wav -> sounds/error.wav
   - C:\Windows\Media\ding.wav -> sounds/ding.wav

2. Download from: https://archive.org/details/windows-98-se-sounds
   - Extract and copy the relevant .wav files

3. Use macOS sounds as fallback (already configured below)

EOF

# Create fallback symlinks to macOS sounds
if [ ! -f tada.wav ] || [ $(stat -f%z tada.wav 2>/dev/null || echo 0) -lt 1000 ]; then
    ln -sf /System/Library/Sounds/Glass.aiff tada.wav 2>/dev/null
    echo "Using macOS Glass.aiff as tada fallback"
fi

if [ ! -f error.wav ] || [ $(stat -f%z error.wav 2>/dev/null || echo 0) -lt 1000 ]; then
    ln -sf /System/Library/Sounds/Basso.aiff error.wav 2>/dev/null
    echo "Using macOS Basso.aiff as error fallback"
fi

if [ ! -f ding.wav ] || [ $(stat -f%z ding.wav 2>/dev/null || echo 0) -lt 1000 ]; then
    ln -sf /System/Library/Sounds/Ping.aiff ding.wav 2>/dev/null
    echo "Using macOS Ping.aiff as ding fallback"
fi

echo ""
echo "Setup complete! Sound files in: $SOUNDS_DIR"
ls -la "$SOUNDS_DIR"
