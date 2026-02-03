# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that plays nostalgic sound effects (dial-up modems, Windows XP, AOL "You've Got Mail") during Claude sessions. The plugin uses Claude Code's hook system to trigger sounds at session lifecycle events.

**Platform**: macOS only (uses `afplay` for audio playback)

## Repository Structure

The repository follows the Claude Code plugin marketplace pattern:
- **Root level**: Marketplace definition (`.claude-plugin/marketplace.json`)
- **plugins/nostalgia-sounds/**: The actual plugin implementation

The plugin itself contains:
- **hooks/hooks.json**: Hook registration for Claude Code events (SessionStart, SessionEnd, UserPromptSubmit, Stop, Notification)
- **config.json**: Sound pack definitions (default, nintendo, sega, mac, windows95, mgs)
- **scripts/**: Bash scripts triggered by hooks
- **sounds/**: MP3/WAV audio files (30+ nostalgic sound effects)

## Key Architecture Concepts

### Hook System Integration
The plugin uses Claude Code's hook system asynchronously to avoid blocking the UI:
- All hooks have `"async": true` to prevent blocking Claude
- Scripts use background processes (`&`) and exit immediately (< 500ms)
- PID file (`/tmp/claude-nostalgia-thinking.pid`) manages long-running "thinking" sounds

### Sound Pack System
The `config.json` defines multiple theme packs. Each pack maps events to sound files:
- **startup/shutdown**: Session lifecycle sounds
- **thinking**: Array of sounds played in sequence (e.g., dialup.mp3 → jeopardy_think_real.mp3)
- **done**: Completion notification
- **notification**: Generic notification sound

The `get-sound.sh` script resolves event names to file paths based on the active pack, with fallback to defaults if `jq` is unavailable.

### Process Management
Critical design constraint: sounds must play asynchronously without blocking Claude.
- **play-dialup.sh**: Kills previous thinking sounds, spawns new background subshell, stores PID
- **play-done.sh**: Kills thinking sounds (via PID file), plays completion sound
- Uses `pkill -9 -f "afplay.*nostalgia-sounds"` as cleanup fallback

### Ctrl+C Limitation
Known limitation: Claude Code's `Stop` hook does not fire on user interrupts (Ctrl+C). The thinking sounds will continue until the next prompt. Users can work around this with a wrapper script that traps SIGINT.

## Development Commands

### Testing
```bash
# Run full test suite
./plugins/nostalgia-sounds/test.sh
```

The test suite validates:
- Required sound files exist
- Scripts are executable and have valid bash syntax
- hooks.json is valid JSON with all hooks async
- Scripts exit quickly (< 500ms, non-blocking)
- Graceful fallback when `afplay` unavailable

### Sound Pack Management
```bash
# List available packs
./plugins/nostalgia-sounds/scripts/set-pack.sh

# Switch to a pack (requires jq)
./plugins/nostalgia-sounds/scripts/set-pack.sh nintendo
```

### Manual Testing
```bash
# Test individual scripts with sample JSON
echo '{"prompt":"test"}' | ./plugins/nostalgia-sounds/scripts/play-dialup.sh

# Test with Claude debug mode
claude --debug
```

### Installation Testing
```bash
# Development mode (point to plugin directory)
claude --plugin-dir ~/nostalgia-sounds/plugins/nostalgia-sounds

# Marketplace mode
/plugin marketplace add jamstop/claude-code-nostalgia-sounds
/plugin install nostalgia-sounds@nostalgia-sounds-marketplace
```

## Development Workflow: Local vs Marketplace Cache

### The Problem
Claude Code caches plugins when installed from a marketplace. This means:
- Your local code changes won't affect the cached marketplace version
- You might accidentally test the old cached version instead of your changes
- Having both versions enabled causes duplicate sounds/hooks

### Recommended Development Workflow

#### Option 1: Use `--plugin-dir` (Best for active development)
```bash
claude --plugin-dir ./plugins/nostalgia-sounds
```
This bypasses the cache entirely. Changes are reflected on each Claude restart.

#### Option 2: Disable marketplace version in settings
Edit `~/.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "nostalgia-sounds@/path/to/workspace/plugins/nostalgia-sounds": true,
    "nostalgia-sounds@nostalgia-sounds-marketplace": false
  }
}
```
Both versions stay installed, but only the local one loads.

#### Option 3: Uninstall marketplace version during development
```
/plugin uninstall nostalgia-sounds@nostalgia-sounds-marketplace
```

### Testing Marketplace Updates
To verify marketplace publishing works:
1. Disable local version, enable marketplace version in settings
2. Clear cache: `rm -rf ~/.claude/plugins/cache/nostalgia-sounds-marketplace`
3. Update marketplace: `/plugin marketplace update nostalgia-sounds-marketplace`
4. Reinstall: `/plugin install nostalgia-sounds`
5. Verify version: check `~/.claude/plugins/cache/nostalgia-sounds-marketplace/nostalgia-sounds/*/.claude-plugin/plugin.json`

### Auto-Detection Gotcha

**Important:** Claude Code auto-detects plugins when you run it from inside a plugin directory. If you're in this workspace and have the marketplace version enabled, you'll get **double sounds** (both versions load).

**Solutions:**

1. **Test marketplace version from a different directory:**
   ```bash
   cd ~
   claude  # Only marketplace plugin loads
   ```

2. **Use `--plugin-dir` to force a specific version:**
   ```bash
   claude --plugin-dir ./plugins/nostalgia-sounds  # Only this version loads
   ```

3. **Temporarily rename `.claude-plugin/` during testing:**
   ```bash
   mv .claude-plugin .claude-plugin.bak  # Prevents auto-detection
   claude  # Only marketplace version loads
   mv .claude-plugin.bak .claude-plugin  # Restore
   ```

4. **Use git worktrees for isolation:**
   ```bash
   # Main worktree for development
   ~/workspace/nostalgia-sounds/

   # Separate worktree for release testing
   git worktree add ~/workspace/nostalgia-sounds-release main
   ```

### Version Bumping
Versions are bumped automatically via GitHub Actions on merge to `main`:
- `feat:` commits → minor bump (1.2.0 → 1.3.0)
- `fix:`, `docs:`, `chore:`, `refactor:` commits → patch bump (1.2.0 → 1.2.1)
- `feat!:` or `BREAKING CHANGE:` → major bump (1.2.0 → 2.0.0)

**Do not manually edit version numbers** - the workflow handles this.

## Important Constraints

### macOS-Specific
- **Required**: `afplay` command (built into macOS)
- **Optional**: `jq` for sound pack switching (`brew install jq`)
- Scripts gracefully exit if `afplay` not found (allows tests to pass on Linux CI)

### Claude Code Hook Requirements
- **All hooks must be async**: Setting `"async": false` will block Claude's UI
- **Scripts must exit quickly**: Target < 500ms, enforced by test suite
- **No blocking on audio playback**: Use background processes (`&`)
- **Use `${CLAUDE_PLUGIN_ROOT}`**: Environment variable for plugin directory in hooks.json

### Avoiding macOS Incompatibilities
- **Don't use `setsid`**: Not available on macOS (enforced by test suite)
- **Avoid `nohup`**: Can cause issues with process cleanup

## File References

When modifying functionality:
- **Hook registration**: plugins/nostalgia-sounds/hooks/hooks.json
- **Sound pack config**: plugins/nostalgia-sounds/config.json
- **Event-to-sound mapping**: plugins/nostalgia-sounds/scripts/get-sound.sh
- **Process management**: plugins/nostalgia-sounds/scripts/play-{dialup,done}.sh
- **Plugin metadata**: plugins/nostalgia-sounds/.claude-plugin/plugin.json
- **Marketplace metadata**: .claude-plugin/marketplace.json
