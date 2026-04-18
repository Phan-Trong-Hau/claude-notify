#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $desc"
        PASS=$((PASS+1))
    else
        echo "FAIL: $desc — expected '$expected', got '$actual'"
        FAIL=$((FAIL+1))
    fi
}

echo "=== config.py tests ==="
CFG="$ROOT/config.json"
assert_eq "enabled is true"     "true"  "$(python3 "$ROOT/scripts/config.py" "$CFG" "enabled" "false")"
assert_eq "volume is 0.8"       "0.8"   "$(python3 "$ROOT/scripts/config.py" "$CFG" "volume" "0")"
assert_eq "sysbeep is true"     "true"  "$(python3 "$ROOT/scripts/config.py" "$CFG" "notify.sysbeep" "false")"
assert_eq "stop message"        "Claude is waiting for your input" \
          "$(python3 "$ROOT/scripts/config.py" "$CFG" "messages.stop" "")"
assert_eq "missing key default" "fallback" \
          "$(python3 "$ROOT/scripts/config.py" "$CFG" "nonexistent.key" "fallback")"
assert_eq "bad path default"    "fallback" \
          "$(python3 "$ROOT/scripts/config.py" "/nonexistent/path.json" "any.key" "fallback")"

echo ""
echo "=== sysbeep.sh tests ==="
bash "$ROOT/scripts/sysbeep.sh" 2>/dev/null
assert_eq "sysbeep exits 0" "0" "$?"

echo ""
echo "=== tts.sh tests ==="
bash "$ROOT/scripts/tts.sh" "Test notification" "0.5" 2>/dev/null
assert_eq "tts exits 0" "0" "$?"
bash "$ROOT/scripts/tts.sh" "" "0.5" 2>/dev/null
assert_eq "tts empty message exits 0" "0" "$?"

echo ""
echo "=== sound.sh tests ==="
bash "$ROOT/scripts/sound.sh" "/nonexistent/file.wav" "0.5" 2>/dev/null
assert_eq "sound nonexistent file exits 0" "0" "$?"
bash "$ROOT/scripts/sound.sh" "" "0.5" 2>/dev/null
assert_eq "sound empty path uses fallback, exits 0" "0" "$?"

echo ""
echo "=== focus.sh tests ==="
# When running tests from terminal, terminal SHOULD be focused → exit 0
bash "$ROOT/scripts/focus.sh"
assert_eq "terminal is focused when running tests" "0" "$?"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
