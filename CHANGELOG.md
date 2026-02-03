# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2026-02-03

### Added
- `update.sh` script for easy cache invalidation and updates

### Fixed
- Notification hook now only triggers for `permission_prompt` and `elicitation_dialog` (fixes random sounds from idle prompts)

### Changed
- Documented hook triggers in README

## [1.3.1] - 2026-02-03

### Added
- Troubleshooting section for plugin cache issues with links to Claude Code GitHub issues

## [1.3.0] - 2026-02-03

### Added
- Auto-update instructions in README
- Version check in `doctor.sh` that compares installed vs latest version from GitHub
- Users can now easily check if updates are available

## [1.2.3] - 2026-02-03

### Fixed
- Shutdown sound now uses `disown` to survive parent process exit
- Previously, shutdown sounds wouldn't play because Claude exited before `afplay` finished

## [1.2.2] - 2026-02-03

### Changed
- Version bump workflow now triggers on `.github/workflows/**` and `AGENTS.md` changes
- Workflow changes can affect the release product, so they should bump versions

## [1.2.1] - 2026-02-03

### Fixed
- Version bump workflow now properly detects conventional commits from:
  - PR titles (via GitHub API)
  - Individual commits in the push
  - Commits from merged branches
- Previously only checked merge commit message which was always "Merge pull request #N"

## [1.2.0] - 2026-02-03

### Added
- **Robust cleanup architecture** with defense-in-depth approach:
  - Parent process monitoring (self-terminates if Claude exits)
  - Reduced safety timeout from 10 minutes to 3 minutes
  - Aggressive cleanup in `SessionEnd` hook
- `AGENTS.md` with development workflow documentation
- Auto-detection gotcha documentation (running from plugin directory loads both versions)

### Fixed
- Thinking sounds now properly stop when Claude finishes or exits
- Cleanup reliability improvements for orphaned audio processes

## [1.1.0] - 2026-02-02

### Added
- Duck Mode sound pack (quacking sounds)
- Programmer Lore sound pack
- Fart Mode sound pack (community contribution)

### Changed
- Replaced preview audio with royalty-free tracks
- Extended thinking loop music (bossa nova, elevator, jazz, lounge)

## [1.0.0] - 2026-02-02

### Added
- Initial release
- Sound packs: default, nintendo, sega, mac, windows95, mgs, lounge, dj
- Random mode for varied sound selection
- User settings stored in `~/.config/nostalgia-sounds/settings.json`
- `doctor.sh` health check script
- `set-pack.sh` and `toggle-random.sh` configuration scripts
- Audio manager daemon for smoother transitions
- Graceful signal handling (SIGTERM before SIGKILL)

### Hooks
- `SessionStart` - startup sounds
- `SessionEnd` - shutdown sounds + cleanup
- `UserPromptSubmit` - thinking sounds (dialup + loop)
- `Stop` - done sounds
- `Notification` - alert sounds

### Sound Categories
- startup, shutdown, thinking, thinkingLoop, done, notification
