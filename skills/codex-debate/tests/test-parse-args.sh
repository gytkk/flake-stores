#!/usr/bin/env bash
# Unit tests for parse_args function
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

PASS=0
FAIL=0

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $test_name"
    PASS=$(( PASS + 1 ))
  else
    echo "  FAIL: $test_name"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    FAIL=$(( FAIL + 1 ))
  fi
}

assert_fails() {
  local test_name="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "  FAIL: $test_name (expected failure but succeeded)"
    FAIL=$(( FAIL + 1 ))
  else
    echo "  PASS: $test_name"
    PASS=$(( PASS + 1 ))
  fi
}

echo "=== parse_args tests ==="

# Test 1: Basic topic only
parse_args "Should we use microservices?"
assert_eq "Topic parsed" "Should we use microservices?" "$TOPIC"
assert_eq "Default rounds" "3" "$ROUNDS"
assert_eq "Default diff" "true" "$DIFF"

# Test 2: All flags
parse_args "Security review" --rounds 5 --files "*.ts" --diff
assert_eq "Topic with flags" "Security review" "$TOPIC"
assert_eq "Custom rounds (odd)" "5" "$ROUNDS"
assert_eq "Files pattern" "*.ts" "$FILES"
assert_eq "Diff flag" "true" "$DIFF"

# Test 3: Even rounds decremented to odd
parse_args "Test topic" --rounds 4
assert_eq "Even rounds decremented" "3" "$ROUNDS"

# Test 4: Rounds of 2 decremented to 1
parse_args "Test topic" --rounds 2
assert_eq "Rounds 2 → 1" "1" "$ROUNDS"

# Test 5: Empty topic
assert_fails "Empty topic rejected" parse_args ""

# Test 6: No topic at all
assert_fails "Missing topic rejected" parse_args --rounds 3

# Test 7: Rounds boundary — 1
parse_args "min rounds" --rounds 1
assert_eq "Rounds 1 → 1 (already odd)" "1" "$ROUNDS"

# Test 8: Rounds boundary — 10 (even, decremented to 9)
parse_args "max rounds" --rounds 10
assert_eq "Rounds 10 → 9 (decremented)" "9" "$ROUNDS"

# Test 9: Quoted topic
parse_args '"Double quoted topic"'
assert_eq "Quoted topic stripped" "Double quoted topic" "$TOPIC"

# Test 10: --files without --diff defaults diff to false (since files specified)
parse_args "topic" --files "src/**/*.ts"
assert_eq "Files specified, diff off" "false" "$DIFF"
assert_eq "Files pattern stored" "src/**/*.ts" "$FILES"

# Test 11: Multi-word bare topic (without quotes)
parse_args Should we use microservices
assert_eq "Multi-word bare topic" "Should we use microservices" "$TOPIC"

# Test 12: Multi-word topic with flags interspersed
parse_args Should we refactor --rounds 5
assert_eq "Multi-word with flags" "Should we refactor" "$TOPIC"
assert_eq "Rounds after multi-word" "5" "$ROUNDS"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
