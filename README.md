# Nostalgia Sounds Plugin for Claude Code

A plugin that brings back the nostalgic sounds of the dial-up internet era to your Claude Code experience.

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
# List available packs
~/.claude/plugins/local/nostalgia-sounds/scripts/set-pack.sh

# Switch to a pack
~/.claude/plugins/local/nostalgia-sounds/scripts/set-pack.sh nintendo
~/.claude/plugins/local/nostalgia-sounds/scripts/set-pack.sh sega
~/.claude/plugins/local/nostalgia-sounds/scripts/set-pack.sh default
```

Or edit `config.json` directly:
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

## Installation

The plugin is already installed at `~/.claude/plugins/local/nostalgia-sounds/`.

To enable it, ensure your `~/.claude/settings.json` includes:

```json
{
  "enabledPlugins": {
    "nostalgia-sounds@local": true
  }
}
```

**Important:** Do NOT add hooks to `settings.json` - they're already defined in the plugin's `hooks/hooks.json`. Adding them to both places will cause sounds to play twice.

## Testing

Run the test suite to verify everything is working:

```bash
~/.claude/plugins/local/nostalgia-sounds/test.sh
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

**The `Stop` hook does not fire on user interrupts.** This is a documented Claude Code limitation:

> "Stop: Runs when the main Claude Code agent has finished responding. **Does not run if the stoppage occurred due to a user interrupt.**"

This means when you press Ctrl+C:
- The thinking sounds (dial-up/jeopardy) will continue playing
- No interrupt sound will play
- Sounds will stop on your next prompt submission

### Workaround: Wrapper Script

To properly handle Ctrl+C interrupts, use a wrapper script that traps the signal:

```bash
#!/bin/bash
# Save as: ~/bin/claude-sounds
# Make executable: chmod +x ~/bin/claude-sounds
# Usage: claude-sounds (instead of claude)

SOUNDS_DIR="$HOME/.claude/plugins/local/nostalgia-sounds/sounds"
INTERRUPT_SOUND="$SOUNDS_DIR/error.wav"

cleanup_on_interrupt() {
    # Kill all plugin sounds immediately
    pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null

    # Play interrupt sound
    [ -f "$INTERRUPT_SOUND" ] && afplay "$INTERRUPT_SOUND" &>/dev/null &

    # Forward interrupt to Claude
    kill -INT "$CLAUDE_PID" 2>/dev/null
    exit 130
}

trap cleanup_on_interrupt SIGINT SIGTERM

# Start Claude in background
claude "$@" &
CLAUDE_PID=$!

# Wait for Claude to finish
wait $CLAUDE_PID
EXIT_CODE=$?

# Check if Claude was interrupted (exit code 130 = SIGINT)
if [ $EXIT_CODE -eq 130 ]; then
    pkill -9 -f "afplay.*nostalgia-sounds" 2>/dev/null
    [ -f "$INTERRUPT_SOUND" ] && afplay "$INTERRUPT_SOUND" &>/dev/null &
fi

exit $EXIT_CODE
```

Then either:
- Use `claude-sounds` instead of `claude`
- Or add an alias to your shell profile: `alias claude='~/bin/claude-sounds'`

## File Structure

```
nostalgia-sounds/
├── README.md                  # This file
├── config.json                # Sound pack configuration
├── test.sh                    # Test suite
├── hooks/
│   └── hooks.json             # Hook configuration
├── scripts/
│   ├── get-sound.sh           # Helper to get sound paths from config
│   ├── set-pack.sh            # CLI to change sound packs
│   ├── play-dialup.sh         # Thinking sounds on prompt submit
│   ├── play-done.sh           # Done sound on completion
│   ├── play-mail.sh           # Notification sound
│   ├── play-session-start.sh  # Startup sound
│   └── play-session-end.sh    # Shutdown sound
└── sounds/
    ├── dialup.mp3             # Dial-up modem sound
    ├── jeopardy_think_real.mp3
    ├── youve_got_mail.mp3
    ├── winxp_startup.mp3
    ├── winxp_shutdown.mp3
    ├── mario_coin.wav
    ├── zelda_secret.wav
    └── ...                    # Many more!
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Full support | Uses `afplay` |
| Linux | Not supported | Would need `paplay` or similar |
| Windows | Not supported | Would need different audio player |

## Troubleshooting

### Sounds playing twice
Remove any `hooks` section from `~/.claude/settings.json`. The plugin's `hooks/hooks.json` should be the only source.

### No sounds at all
1. Check plugin is enabled: `"nostalgia-sounds@local": true` in settings
2. Verify `afplay` is available (macOS only)
3. Check sound files exist: `ls ~/.claude/plugins/local/nostalgia-sounds/sounds/`
4. Run `./test.sh` to diagnose issues

### Sounds don't stop on Ctrl+C
This is expected - see [Known Limitations](#known-limitations). Use the wrapper script.

### Startup/shutdown sounds not playing
Restart Claude Code - hooks are loaded at startup.

## Related Links

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Feature Request: UserInterrupt Hook](https://github.com/anthropics/claude-code/issues/9516)

## License

MIT - Do whatever you want with it.
