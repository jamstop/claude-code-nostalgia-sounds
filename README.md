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

## Sound Packs

Choose from several nostalgic sound packs:

| Pack | Description |
|------|-------------|
| **default** | 90s Internet - Dial-up modems, Windows XP, AOL |
| **nintendo** | Classic Nintendo - GameBoy startup, Zelda secret, Mario coins |
| **sega** | Sega Genesis - SEGA! Sonic rings |
| **mac** | Classic Mac - Macintosh startup sounds |
| **windows95** | Windows 95 - The original Windows experience |
| **mgs** | Metal Gear Solid - PS1 startup, alert sounds |

### Changing Sound Packs

```bash
# Find your plugin installation (marketplace installs to ~/.claude/plugins/marketplaces/)
PLUGIN_DIR=$(find ~/.claude/plugins -name "nostalgia-sounds" -type d | grep -v cache | head -1)

# List available packs
$PLUGIN_DIR/scripts/set-pack.sh

# Switch to a pack
$PLUGIN_DIR/scripts/set-pack.sh nintendo
```

Or edit `config.json` directly in the plugin directory:
```json
{
  "activePack": "nintendo"
}
```

## Sound Events

| Event | Default Sound | Description |
|-------|---------------|-------------|
| **Session Start** | Windows XP Startup | Plays when you start Claude Code |
| **Session End** | Windows XP Shutdown | Plays when you exit Claude Code |
| **Thinking** | Dial-up + Jeopardy | Connection sound, then thinking music while Claude works |
| **Done** | "You've Got Mail!" | AOL mail notification when Claude finishes |
| **Notification** | "You've Got Mail!" | Plays on Claude notifications |

## Requirements

- **macOS** (uses `afplay` for audio playback)
- **jq** (for sound pack switching): `brew install jq`

## Testing

```bash
# Run the test suite
./plugins/nostalgia-sounds/test.sh
```

For live debugging:
- Run `claude --debug` to see hook execution
- Press `Ctrl+O` during a session for verbose mode

## Custom Sound Packs

Add your own pack to `config.json`:

```json
{
  "activePack": "my-custom-pack",
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

Then add your sound files to the `sounds/` directory.

## Known Limitations

### Ctrl+C Interrupt Detection

**The `Stop` hook does not fire on user interrupts.** This is a documented Claude Code limitation.

When you press Ctrl+C:
- The thinking sounds will continue playing
- Sounds will stop on your next prompt submission

### Workaround: Wrapper Script

```bash
#!/bin/bash
# Save as: ~/bin/claude-sounds
# chmod +x ~/bin/claude-sounds

cleanup() {
    pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null
    kill -INT "$PID" 2>/dev/null
    exit 130
}
trap cleanup SIGINT SIGTERM

claude "$@" &
PID=$!
wait $PID
```

Then use `claude-sounds` instead of `claude`, or alias it.

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
        ├── config.json        # Sound pack configuration
        ├── test.sh            # Test suite
        ├── hooks/
        │   └── hooks.json     # Hook configuration
        ├── scripts/
        │   ├── get-sound.sh
        │   ├── set-pack.sh
        │   ├── play-dialup.sh
        │   ├── play-done.sh
        │   ├── play-mail.sh
        │   ├── play-session-start.sh
        │   └── play-session-end.sh
        └── sounds/
            ├── dialup.mp3
            ├── jeopardy_think_real.mp3
            ├── youve_got_mail.mp3
            └── ...            # 30+ sound files
```

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

### Can't change sound packs
Install jq: `brew install jq`

## License

MIT
