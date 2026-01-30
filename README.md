# Nostalgia Sounds Plugin for Claude Code

A plugin that brings back the nostalgic sounds of the dial-up internet era to your Claude Code experience.

## Sounds

| Event | Sound | Description |
|-------|-------|-------------|
| **Session Start** | Windows XP Startup | Plays when you start Claude Code |
| **Session End** | Windows XP Shutdown | Plays when you exit Claude Code |
| **Prompt Submit** | Dial-up modem + Jeopardy | Dial-up connection sound, then Jeopardy thinking music while Claude works |
| **Task Complete** | "You've Got Mail!" | AOL mail notification when Claude finishes |
| **Tool Error** | Error beep | Plays when a tool fails |
| **Interrupt (Ctrl+C)** | Error beep | Plays when you interrupt Claude (requires wrapper - see below) |
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

### How Exit Codes Work

When a process is killed by a signal, it exits with code `128 + signal_number`:

| Signal | Number | Exit Code | Meaning |
|--------|--------|-----------|---------|
| SIGINT | 2 | **130** | User pressed Ctrl+C |
| SIGTERM | 15 | 143 | Terminated |
| SIGKILL | 9 | 137 | Force killed |

The wrapper script checks for exit code 130 to detect interrupts.

### Why Can't This Be Fixed in the Plugin?

1. **No `UserInterrupt` hook exists** - [Feature request #9516](https://github.com/anthropics/claude-code/issues/9516)
2. **Plugins can't create custom hooks** - Only respond to existing events
3. **Exit codes only visible outside Claude** - Hooks run during execution, not after

## File Structure

```
nostalgia-sounds/
├── README.md                  # This file
├── hooks/
│   └── hooks.json             # Hook configuration
├── scripts/
│   ├── play-dialup.sh         # Dial-up + Jeopardy on prompt submit
│   ├── play-done.sh           # "You've Got Mail" on completion
│   ├── play-error.sh          # Error sound on tool failure
│   ├── play-mail.sh           # Mail sound on notifications
│   ├── play-session-start.sh  # XP startup on session start
│   └── play-session-end.sh    # XP shutdown on session end
└── sounds/
    ├── dialup.mp3             # Dial-up modem sound
    ├── jeopardy_think_real.mp3    # Jeopardy thinking music
    ├── youve_got_mail.mp3     # AOL "You've Got Mail!"
    ├── error.wav              # Error/interrupt sound
    ├── winxp_startup.mp3      # Windows XP startup
    ├── winxp_shutdown.mp3     # Windows XP shutdown
    └── ...                    # Other sound files
```

## How It Works

### Sound Overlap Prevention

The `play-dialup.sh` script:
1. Kills any existing sounds before starting new ones
2. Tracks process IDs in `/tmp/claude-nostalgia-sound.pid`
3. Uses pattern matching (`pkill -f`) as a backup

### Interrupt vs Completion Detection

The `play-done.sh` script checks if sounds are still playing:
- **Still playing** = User interrupted (plays error sound)
- **Not playing** = Normal completion (plays "You've Got Mail")

This works for the `Stop` hook (normal completion) but NOT for Ctrl+C (which doesn't trigger `Stop`).

## Troubleshooting

### Sounds playing twice
Remove any `hooks` section from `~/.claude/settings.json`. The plugin's `hooks/hooks.json` should be the only source.

### No sounds at all
1. Check plugin is enabled: `"nostalgia-sounds@local": true` in settings
2. Verify `afplay` is available (macOS only)
3. Check sound files exist: `ls ~/.claude/plugins/local/nostalgia-sounds/sounds/`

### Sounds don't stop on Ctrl+C
This is expected - see [Known Limitations](#known-limitations). Use the wrapper script.

### Startup/shutdown sounds not playing
Restart Claude Code - hooks are loaded at startup.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Full support | Uses `afplay` |
| Linux | Not supported | Would need `paplay` or similar |
| Windows | Not supported | Would need different audio player |

## Customizing Sounds

### Swap sound files
Replace any `.mp3` or `.wav` file in `sounds/` with your own. Keep the same filename.

### Change which sound plays
Edit the scripts in `scripts/` to point to different sound files.

### Add new sounds
1. Add your sound file to `sounds/`
2. Create or modify a script in `scripts/`
3. Add a hook in `hooks/hooks.json` if needed

## Related Links

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Feature Request: UserInterrupt Hook](https://github.com/anthropics/claude-code/issues/9516)
- [Feature Request: Notification Reason Field](https://github.com/anthropics/claude-code/issues/11189)
- [Bug: Ctrl+C Doesn't Stop Execution](https://github.com/anthropics/claude-code/issues/3455)

## License

MIT - Do whatever you want with it.
