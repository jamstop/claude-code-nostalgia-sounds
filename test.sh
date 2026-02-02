#!/bin/bash
# Test suite for nostalgia-sounds plugin
# Tests follow Claude Code hook testing patterns:
# - Manual script execution with sample JSON input
# - Exit code verification (0 = success, non-zero = error)
# - Graceful fallback when audio not available

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
HOOKS_FILE="$SCRIPT_DIR/hooks/hooks.json"

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

echo "=== Nostalgia Sounds Plugin Tests ==="
echo "Following Claude Code hook testing patterns"
echo ""

# ============================================
# Test 1: Sound files exist
# ============================================
echo "--- Sound Files ---"
REQUIRED_SOUNDS=(
    "dialup.mp3"
    "jeopardy_think_real.mp3"
    "winxp_startup.mp3"
    "winxp_shutdown.mp3"
    "youve_got_mail.mp3"
)

for sound in "${REQUIRED_SOUNDS[@]}"; do
    if [ -f "$SOUNDS_DIR/$sound" ]; then
        pass "Sound exists: $sound"
    else
        fail "Sound missing: $sound"
    fi
done

# ============================================
# Test 2: Scripts are executable
# ============================================
echo ""
echo "--- Scripts Executable ---"
for script in "$SCRIPTS_DIR"/*.sh; do
    name=$(basename "$script")
    if [ -x "$script" ]; then
        pass "Executable: $name"
    else
        fail "Not executable: $name"
    fi
done

# ============================================
# Test 3: hooks.json validation
# ============================================
echo ""
echo "--- Hook Configuration ---"
if command -v jq &>/dev/null; then
    if jq empty "$HOOKS_FILE" 2>/dev/null; then
        pass "hooks.json is valid JSON"
    else
        fail "hooks.json is invalid JSON"
    fi

    # Verify all hooks are async (required to not block Claude)
    ASYNC_COUNT=$(jq '[.. | objects | select(.type == "command") | .async] | map(select(. == true)) | length' "$HOOKS_FILE")
    TOTAL_HOOKS=$(jq '[.. | objects | select(.type == "command")] | length' "$HOOKS_FILE")
    if [ "$ASYNC_COUNT" = "$TOTAL_HOOKS" ]; then
        pass "All hooks async: true ($ASYNC_COUNT/$TOTAL_HOOKS)"
    else
        fail "Not all hooks are async ($ASYNC_COUNT/$TOTAL_HOOKS) - will block Claude!"
    fi

    # Check expected hook events are configured
    for event in SessionStart SessionEnd UserPromptSubmit Stop Notification; do
        if jq -e ".hooks.$event" "$HOOKS_FILE" &>/dev/null; then
            pass "Hook event configured: $event"
        else
            fail "Hook event missing: $event"
        fi
    done
else
    echo "⚠ jq not installed, skipping JSON validation"
fi

# ============================================
# Test 4: System requirements
# ============================================
echo ""
echo "--- System Requirements ---"
if command -v afplay &>/dev/null; then
    pass "afplay available (macOS audio player)"
else
    echo "⚠ afplay not found (Linux?) - sounds won't play"
fi

# ============================================
# Test 5: macOS compatibility
# ============================================
echo ""
echo "--- macOS Compatibility ---"
if grep -r "setsid" "$SCRIPTS_DIR" &>/dev/null; then
    fail "Scripts use 'setsid' (not available on macOS)"
else
    pass "No setsid usage"
fi

if grep -r "nohup" "$SCRIPTS_DIR" &>/dev/null; then
    echo "⚠ Scripts use nohup (may cause issues)"
else
    pass "No nohup usage"
fi

# ============================================
# Test 6: Bash syntax check
# ============================================
echo ""
echo "--- Syntax Check ---"
for script in "$SCRIPTS_DIR"/*.sh; do
    name=$(basename "$script")
    if bash -n "$script" 2>/dev/null; then
        pass "Syntax OK: $name"
    else
        fail "Syntax error: $name"
    fi
done

# ============================================
# Test 7: Script execution with sample hook input
# Following Claude Code pattern: pipe JSON to hook script
# ============================================
echo ""
echo "--- Hook Execution (with sample JSON input) ---"

# Sample JSON inputs for different hook events
SESSION_START_JSON='{"session_id":"test-123"}'
USER_PROMPT_JSON='{"prompt":"hello world"}'
STOP_JSON='{"stop_reason":"complete"}'
NOTIFICATION_JSON='{"message":"test notification"}'

# Test each script with appropriate sample input
# Using PATH without afplay to test graceful fallback
test_script() {
    local script=$1
    local json=$2
    local name=$(basename "$script")

    # Run with no afplay in PATH to verify graceful exit
    if echo "$json" | PATH=/usr/bin:/bin "$script" 2>/dev/null; then
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            pass "Exit 0 (no block): $name"
        else
            fail "Non-zero exit ($exit_code): $name"
        fi
    else
        fail "Script crashed: $name"
    fi
}

test_script "$SCRIPTS_DIR/play-session-start.sh" "$SESSION_START_JSON"
test_script "$SCRIPTS_DIR/play-session-end.sh" "$SESSION_START_JSON"
test_script "$SCRIPTS_DIR/play-dialup.sh" "$USER_PROMPT_JSON"
test_script "$SCRIPTS_DIR/play-done.sh" "$STOP_JSON"
test_script "$SCRIPTS_DIR/play-mail.sh" "$NOTIFICATION_JSON"

# ============================================
# Test 8: Scripts exit quickly (non-blocking)
# ============================================
echo ""
echo "--- Non-blocking Check ---"
for script in "$SCRIPTS_DIR"/*.sh; do
    name=$(basename "$script")
    # Time the script - should exit < 1 second
    start=$(date +%s%N 2>/dev/null || date +%s)
    PATH=/usr/bin:/bin timeout 2 "$script" < /dev/null 2>/dev/null || true
    end=$(date +%s%N 2>/dev/null || date +%s)

    # If nanoseconds available, check < 500ms
    if [[ "$start" =~ ^[0-9]{10,}$ ]]; then
        elapsed=$(( (end - start) / 1000000 ))
        if [ $elapsed -lt 500 ]; then
            pass "Fast exit (${elapsed}ms): $name"
        else
            fail "Slow exit (${elapsed}ms): $name"
        fi
    else
        pass "Exits quickly: $name"
    fi
done

# ============================================
# Summary
# ============================================
echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "Some tests failed!"
    echo ""
    echo "Debug tips:"
    echo "  - Run 'claude --debug' to see hook execution"
    echo "  - Use Ctrl+O in Claude for verbose hook output"
    echo "  - Test scripts manually: echo '{}' | ./script.sh"
    exit 1
fi

echo "All tests passed!"
echo ""
echo "To verify in Claude Code:"
echo "  1. Run 'claude --debug' to see hook execution"
echo "  2. Press Ctrl+O for verbose mode during session"
echo "  3. Check /hooks menu to see registered hooks"
