#!/bin/bash
# Test suite for nostalgia-sounds plugin
# Tests follow Claude Code hook testing patterns:
# - Manual script execution with sample JSON input
# - Exit code verification (0 = success, non-zero = error)
# - Graceful fallback when audio not available

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
HOOKS_FILE="$SCRIPT_DIR/hooks/hooks.json"
CONFIG_FILE="$SCRIPT_DIR/config.json"

PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

echo "=== Nostalgia Sounds Plugin Tests ==="
echo ""

# ============================================
# Test 1: Sound files exist (core sounds)
# ============================================
echo "--- Core Sound Files ---"
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
# Test 2: Config.json validation
# ============================================
echo ""
echo "--- Config Validation ---"
if command -v jq &>/dev/null; then
    if jq empty "$CONFIG_FILE" 2>/dev/null; then
        pass "config.json is valid JSON"
    else
        fail "config.json is invalid JSON"
    fi

    # Check required fields
    if jq -e '.activePack' "$CONFIG_FILE" &>/dev/null; then
        pass "config.json has activePack"
    else
        fail "config.json missing activePack"
    fi

    if jq -e '.randomMode' "$CONFIG_FILE" &>/dev/null; then
        RANDOM_MODE=$(jq -r '.randomMode' "$CONFIG_FILE")
        pass "config.json has randomMode: $RANDOM_MODE"
    else
        fail "config.json missing randomMode"
    fi

    if jq -e '.soundCategories' "$CONFIG_FILE" &>/dev/null; then
        pass "config.json has soundCategories"
    else
        fail "config.json missing soundCategories"
    fi

    if jq -e '.packs' "$CONFIG_FILE" &>/dev/null; then
        pass "config.json has packs"
    else
        fail "config.json missing packs"
    fi
else
    echo "⚠ jq not installed, skipping config validation"
fi

# ============================================
# Test 3: All sounds in soundCategories exist
# ============================================
echo ""
echo "--- Sound Categories Validation ---"
if command -v jq &>/dev/null; then
    CATEGORIES=("startup" "shutdown" "thinking" "thinkingLoop" "done" "notification")
    for cat in "${CATEGORIES[@]}"; do
        SOUNDS=$(jq -r ".soundCategories.$cat // [] | .[]" "$CONFIG_FILE" 2>/dev/null)
        if [ -z "$SOUNDS" ]; then
            fail "Category empty or missing: $cat"
        else
            MISSING=0
            for sound in $SOUNDS; do
                if [ ! -f "$SOUNDS_DIR/$sound" ]; then
                    fail "Sound in $cat not found: $sound"
                    MISSING=$((MISSING + 1))
                fi
            done
            if [ $MISSING -eq 0 ]; then
                COUNT=$(echo "$SOUNDS" | wc -l | tr -d ' ')
                pass "Category $cat: all $COUNT sounds exist"
            fi
        fi
    done
fi

# ============================================
# Test 4: All sounds in packs exist
# ============================================
echo ""
echo "--- Sound Packs Validation ---"
if command -v jq &>/dev/null; then
    PACKS=$(jq -r '.packs | keys[]' "$CONFIG_FILE" 2>/dev/null)
    for pack in $PACKS; do
        MISSING=0
        # Check each sound type in the pack
        for event in startup shutdown done notification; do
            SOUND=$(jq -r ".packs[\"$pack\"].sounds.$event // empty" "$CONFIG_FILE" 2>/dev/null)
            if [ -n "$SOUND" ] && [ "$SOUND" != "null" ]; then
                if [ ! -f "$SOUNDS_DIR/$SOUND" ]; then
                    fail "Pack $pack.$event not found: $SOUND"
                    MISSING=$((MISSING + 1))
                fi
            fi
        done
        # Check thinking array
        THINKING=$(jq -r ".packs[\"$pack\"].sounds.thinking // [] | .[]" "$CONFIG_FILE" 2>/dev/null)
        for sound in $THINKING; do
            if [ ! -f "$SOUNDS_DIR/$sound" ]; then
                fail "Pack $pack.thinking not found: $sound"
                MISSING=$((MISSING + 1))
            fi
        done
        if [ $MISSING -eq 0 ]; then
            pass "Pack $pack: all sounds exist"
        fi
    done
fi

# ============================================
# Test 5: Scripts are executable
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
# Test 6: hooks.json validation
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
    for event in SessionStart SessionEnd UserPromptSubmit PreToolUse Stop Notification; do
        if jq -e ".hooks.$event" "$HOOKS_FILE" &>/dev/null; then
            pass "Hook event configured: $event"
        else
            fail "Hook event missing: $event"
        fi
    done
fi

# ============================================
# Test 7: System requirements
# ============================================
echo ""
echo "--- System Requirements ---"
if command -v afplay &>/dev/null; then
    pass "afplay available (macOS audio player)"
else
    echo "⚠ afplay not found (Linux?) - sounds won't play"
fi

if command -v jq &>/dev/null; then
    pass "jq available (JSON processor)"
else
    echo "⚠ jq not found - pack switching won't work"
fi

# ============================================
# Test 8: Bash syntax check
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
# Test 9: get-sound.sh functionality
# ============================================
echo ""
echo "--- get-sound.sh Tests ---"
if command -v jq &>/dev/null; then
    # Test that get-sound.sh returns valid paths
    for event in startup shutdown done notification; do
        SOUND=$("$SCRIPTS_DIR/get-sound.sh" "$event" 2>/dev/null)
        if [ -n "$SOUND" ] && [ -f "$SOUND" ]; then
            pass "get-sound.sh $event returns valid file"
        else
            fail "get-sound.sh $event failed: $SOUND"
        fi
    done

    # Test thinking sounds (index 0 and 1)
    SOUND_0=$("$SCRIPTS_DIR/get-sound.sh" thinking 0 2>/dev/null)
    SOUND_1=$("$SCRIPTS_DIR/get-sound.sh" thinking 1 2>/dev/null)
    if [ -n "$SOUND_0" ] && [ -f "$SOUND_0" ]; then
        pass "get-sound.sh thinking 0 returns valid file"
    else
        fail "get-sound.sh thinking 0 failed"
    fi
    if [ -n "$SOUND_1" ] && [ -f "$SOUND_1" ]; then
        pass "get-sound.sh thinking 1 returns valid file"
    else
        fail "get-sound.sh thinking 1 failed"
    fi
fi

# ============================================
# Test 10: Random mode produces variety
# ============================================
echo ""
echo "--- Random Mode Test ---"
if command -v jq &>/dev/null; then
    RANDOM_MODE=$(jq -r '.randomMode' "$CONFIG_FILE")
    if [ "$RANDOM_MODE" = "true" ]; then
        # Run get-sound.sh multiple times and check for variety
        SOUNDS=""
        for i in {1..10}; do
            SOUND=$("$SCRIPTS_DIR/get-sound.sh" done 2>/dev/null | xargs basename)
            SOUNDS="$SOUNDS$SOUND"$'\n'
        done
        UNIQUE=$(echo "$SOUNDS" | sort -u | grep -c .)
        if [ "$UNIQUE" -gt 1 ]; then
            pass "Random mode produces variety: $UNIQUE unique sounds in 10 runs"
        else
            fail "Random mode not varying: only saw $UNIQUE sound(s)"
        fi
    else
        echo "⚠ Random mode disabled, skipping variety test"
    fi
fi

# ============================================
# Test 11: toggle-random.sh functionality
# ============================================
echo ""
echo "--- toggle-random.sh Test ---"
if command -v jq &>/dev/null; then
    # Save current state
    ORIGINAL=$(jq -r '.randomMode' "$CONFIG_FILE")

    # Test toggle off
    "$SCRIPTS_DIR/toggle-random.sh" off >/dev/null 2>&1
    STATE=$(jq -r '.randomMode' "$CONFIG_FILE")
    if [ "$STATE" = "false" ]; then
        pass "toggle-random.sh off works"
    else
        fail "toggle-random.sh off failed"
    fi

    # Test toggle on
    "$SCRIPTS_DIR/toggle-random.sh" on >/dev/null 2>&1
    STATE=$(jq -r '.randomMode' "$CONFIG_FILE")
    if [ "$STATE" = "true" ]; then
        pass "toggle-random.sh on works"
    else
        fail "toggle-random.sh on failed"
    fi

    # Restore original state
    "$SCRIPTS_DIR/toggle-random.sh" "$ORIGINAL" >/dev/null 2>&1
fi

# ============================================
# Test 12: Script execution (graceful fallback)
# ============================================
echo ""
echo "--- Script Execution (no audio) ---"

test_script() {
    local script=$1
    local name=$(basename "$script")

    # Run script (afplay will be available but audio plays in background)
    # We just want to verify the script exits cleanly
    if "$script" </dev/null 2>/dev/null; then
        pass "Graceful exit: $name"
    else
        fail "Script crashed: $name"
    fi
}

test_script "$SCRIPTS_DIR/play-session-start.sh"
test_script "$SCRIPTS_DIR/play-session-end.sh"
test_script "$SCRIPTS_DIR/play-dialup.sh"
test_script "$SCRIPTS_DIR/play-done.sh"
test_script "$SCRIPTS_DIR/play-mail.sh"
test_script "$SCRIPTS_DIR/stop-thinking.sh"

# ============================================
# Test 13: Scripts exit quickly (non-blocking)
# ============================================
echo ""
echo "--- Non-blocking Check ---"
for script in "$SCRIPTS_DIR"/*.sh; do
    name=$(basename "$script")
    # Time the script - should exit < 1 second
    start=$(date +%s%N 2>/dev/null || date +%s)
    timeout 2 "$script" < /dev/null 2>/dev/null || true
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
# Test 14: macOS compatibility
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
    echo "  - Test scripts manually: ./scripts/get-sound.sh done"
    exit 1
fi

echo "All tests passed!"
