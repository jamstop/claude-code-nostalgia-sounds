# Nostalgia Sounds Plugin for Claude Code

A plugin that brings back the nostalgic sounds of the dial-up internet era to your Claude Code experience.

## Installation

### Option 1: Marketplace (Recommended)

```bash
# Add this repo as a plugin marketplace
/plugin marketplace add jamstop/claude-code-nostalgia-sounds

# Install the plugin
/plugin install nostalgia-sounds@nostalgia-sounds-marketplace
```

### Option 2: Development / Testing

```bash
# Clone the repository
git clone https://github.com/jamstop/claude-code-nostalgia-sounds.git ~/nostalgia-sounds

# Run Claude with the plugin (point to the plugin subdirectory)
claude --plugin-dir ~/nostalgia-sounds/plugins/nostalgia-sounds
```

After installation, restart Claude Code.

## How It Works

By default, **Random Mode is enabled**. Each sound event picks a random sound from its category:

| Event | When it plays | Example sounds |
|-------|---------------|----------------|
| **startup** | Session start | Windows XP, Mac, GameBoy, PS1, SEGA |
| **shutdown** | Session end | Windows shutdown, record scratch |
| **thinking** | User submits prompt | Dialup modem |
| **thinkingLoop** | While Claude thinks (loops continuously) | Jeopardy, elevator music, bossa nova, smooth jazz, trap beats |
| **done** | Claude finishes | "You've Got Mail!", Zelda secret, air horn, bass drop |
| **notification** | Claude notifications | Various alert sounds, air horn |

In random mode, thinking plays a dialup sound followed by random thinking loops that continue until Claude finishes.

## User Settings

Your personal preferences are stored separately from the plugin code in `~/.config/nostalgia-sounds/settings.json`. This means:

- **Your settings won't be overwritten** when the plugin updates
- **You won't accidentally commit** your personal preferences to git
- **Multiple users** can have different settings on the same machine

Settings you can customize:
- `randomMode` - true/false
- `activePack` - which sound pack to use

## Adding New Sounds

### Step 1: Add the sound file

Place your sound file (`.mp3` or `.wav`) in the `sounds/` directory:

```bash
cp my-cool-sound.mp3 plugins/nostalgia-sounds/sounds/
```

### Step 2: Add to sound categories

Edit `config.json` and add your sound to the appropriate category in `soundCategories`:

```json
{
  "soundCategories": {
    "done": [
      "ding.wav",
      "mario_coin.wav",
      "my-cool-sound.mp3"
    ]
  }
}
```

Your sound will now be included in random selection for that event.

### Step 3: Normalize volume (recommended)

For consistent volume, normalize your sound to -16 LUFS:

```bash
ffmpeg -i my-sound.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 44100 my-sound-normalized.mp3
```

### Available Categories

| Category | Purpose |
|----------|---------|
| `startup` | Session start sounds |
| `shutdown` | Session end sounds |
| `thinking` | Initial "connecting" sounds (dialup) |
| `thinkingLoop` | Looping wait music (jeopardy, jazz, etc.) |
| `done` | Completion/success sounds |
| `notification` | Alert/notification sounds |

## Configuration

### Toggle Random Mode

Random mode is **on by default**. To toggle:

```bash
# Find your plugin installation
PLUGIN_DIR=~/.claude/plugins/cache/nostalgia-sounds-marketplace/nostalgia-sounds/*/scripts

# Toggle random mode
$PLUGIN_DIR/toggle-random.sh

# Or explicitly set it
$PLUGIN_DIR/toggle-random.sh on
$PLUGIN_DIR/toggle-random.sh off
```

Settings are saved to `~/.config/nostalgia-sounds/settings.json`.

### Changing Sound Packs

```bash
# List available packs
$PLUGIN_DIR/set-pack.sh

# Switch to a pack
$PLUGIN_DIR/set-pack.sh nintendo
```

## Sound Packs

If you disable random mode, you can use curated sound packs instead:

| Pack | Description |
|------|-------------|
| **default** | 90s Internet - Dial-up modems, Windows XP, AOL |
| **lounge** | Lounge & Jazz - Smooth elevator music, bossa nova, jazz vibes |
| **dj** | DJ / 808 - Air horns, bass drops, trap beats |
| **nintendo** | Classic Nintendo - GameBoy startup, Zelda secret, Mario coins |
| **sega** | Sega Genesis - SEGA! Sonic rings |
| **mac** | Classic Mac - Macintosh startup sounds |
| **windows95** | Windows 95 - The original Windows experience |
| **mgs** | Metal Gear Solid - PS1 startup, alert sounds |

### Creating Custom Packs

Add your own pack to `config.json`:

```json
{
  "packs": {
    "my-custom-pack": {
      "name": "My Custom Pack",
      "description": "My personalized sounds",
      "sounds": {
        "startup": "my-startup.mp3",
        "shutdown": "my-shutdown.mp3",
        "thinking": ["my-dialup.mp3", "my-thinking.mp3"],
        "done": "my-done.mp3",
        "notification": "my-notification.mp3"
      }
    }
  }
}
```

**Note:** Custom pack sounds should also be added to `soundCategories` so they're included when random mode is enabled.

## Advanced Features

### Audio Manager (Auto-started)

The plugin includes a long-running audio manager daemon that:
- Reduces process spawning/killing overhead
- Provides smoother audio transitions
- Uses graceful signal handling to prevent audio glitches

The manager starts automatically with your Claude session.

### Sox Crossfading (Optional)

For smoother transitions between thinking loop sounds, install sox:

```bash
brew install sox
```

When sox is available, the audio manager will use fade-in/fade-out effects between sounds.

## Requirements

- **macOS** (uses `afplay` for audio playback)
- **jq** (for configuration): `brew install jq`
- **sox** (optional, for crossfading): `brew install sox`
- **ffmpeg** (optional, for normalizing sounds): `brew install ffmpeg`

## Testing

```bash
# Run the test suite
./plugins/nostalgia-sounds/test.sh
```

For live debugging:
- Run `claude --debug` to see hook execution
- Press `Ctrl+O` during a session for verbose mode

## Known Limitations

### Ctrl+C Interrupt Detection

**The `Stop` hook does not fire on user interrupts.** This is a documented Claude Code limitation.

When you press Ctrl+C:
- The thinking sounds will continue playing briefly
- A 10-minute safety timeout ensures sounds eventually stop
- Sounds will stop on your next prompt submission

### Workaround: Wrapper Script

```bash
#!/bin/bash
# Save as: ~/bin/claude-sounds
# chmod +x ~/bin/claude-sounds

cleanup() {
    pkill -f "afplay.*nostalgia-sounds" 2>/dev/null
    kill -INT "$PID" 2>/dev/null
    exit 130
}
trap cleanup SIGINT SIGTERM

claude "$@" &
PID=$!
wait $PID
```

Then use `claude-sounds` instead of `claude`, or alias it.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Full support | Uses `afplay` |
| Linux | Not supported | Would need `paplay` |
| Windows | Not supported | Would need different player |

## Troubleshooting

### No sounds at all
1. Verify `afplay` is available: `which afplay`
2. Run `claude --debug` to see if hooks are firing
3. Check `/hooks` in Claude Code to see registered hooks
4. Run `./plugins/nostalgia-sounds/test.sh`

### Sounds playing twice
You may have duplicate plugin installations. Check:
```bash
/plugin list
```
Uninstall duplicates if present.

### Can't change configuration
Install jq: `brew install jq`

### Audio glitches or system audio issues
The plugin uses graceful signal handling (SIGTERM before SIGKILL) to prevent audio issues. If you experience problems:
```bash
# Kill any stray audio processes
pkill -f "afplay.*nostalgia-sounds"
pkill -f "audio-manager.sh"

# Remove stale files
rm -f /tmp/claude-nostalgia-*
```

## Repository Structure

```
claude-code-nostalgia-sounds/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace definition
├── README.md
└── plugins/
    └── nostalgia-sounds/      # The actual plugin
        ├── .claude-plugin/
        │   └── plugin.json    # Plugin manifest
        ├── config.json        # Sound pack configuration (defaults)
        ├── test.sh            # Test suite
        ├── hooks/
        │   └── hooks.json     # Hook configuration
        ├── scripts/
        │   ├── audio-cmd.sh       # Audio helper functions
        │   ├── audio-manager.sh   # Long-running audio daemon
        │   ├── get-sound.sh       # Sound file resolution
        │   ├── set-pack.sh        # Change active pack
        │   ├── toggle-random.sh   # Toggle random mode
        │   ├── play-dialup.sh     # Thinking sounds (loops)
        │   ├── play-done.sh       # Done sound
        │   ├── play-mail.sh       # Notification sound
        │   ├── stop-thinking.sh   # Stop thinking sounds
        │   ├── play-session-start.sh
        │   └── play-session-end.sh
        └── sounds/
            ├── dialup.mp3
            ├── jeopardy_think_real.mp3
            ├── youve_got_mail.mp3
            └── ...            # 30+ sound files

~/.config/nostalgia-sounds/    # User settings (not in repo)
    └── settings.json          # Your personal preferences
```

## License

MIT
