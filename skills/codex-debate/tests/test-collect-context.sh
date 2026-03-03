#!/usr/bin/env bash
# Unit tests for collect_context and truncation logic
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

PASS=0
FAIL=0

# Use temp directory with a git repo for test isolation
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
cd "$TEST_DIR"
git init -q
git config user.name "test"
git config user.email "test@test.local"
echo "hello world" > test.txt
git add test.txt
git commit -q -m "initial"

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

assert_contains() {
  local test_name="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $test_name"
    PASS=$(( PASS + 1 ))
  else
    echo "  FAIL: $test_name (does not contain '$needle')"
    FAIL=$(( FAIL + 1 ))
  fi
}

echo "=== collect_context tests ==="

# Test 1: Diff context from last commit
collect_context --diff
assert_eq "Diff lines captured" "0" "$CONTEXT_DIFF_LINES"
# No diff since clean state, that's ok — tests the path

# Test 2: Create a change and capture diff
echo "new line" >> test.txt
collect_context --diff
if [[ "$CONTEXT_DIFF_LINES" -gt 0 ]]; then
  echo "  PASS: Diff lines > 0 after change"
  PASS=$(( PASS + 1 ))
else
  echo "  FAIL: Expected diff lines > 0, got $CONTEXT_DIFF_LINES"
  FAIL=$(( FAIL + 1 ))
fi

# Test 3: Secret masking in diff context
echo "api_key=SuperSecretKey123" >> test.txt
collect_context --diff
if [[ "$CONTEXT_SUMMARY" != *"SuperSecretKey123"* ]]; then
  echo "  PASS: Secrets masked in diff context"
  PASS=$(( PASS + 1 ))
else
  echo "  FAIL: Secret not masked in context"
  FAIL=$(( FAIL + 1 ))
fi
assert_contains "Redacted marker present" "[REDACTED]" "$CONTEXT_SUMMARY"

# Test 4: Truncation
# Create a large file
python3 -c "print('x' * 100, end='')" > /dev/null 2>&1 || true
LARGE_TEXT=$(head -c 3000 /dev/urandom | base64 | head -c 3000)
echo "$LARGE_TEXT" > large.txt
git add large.txt
collect_context --diff --max-chars 100
if [[ "$CONTEXT_SUMMARY" == *"truncated"* ]]; then
  echo "  PASS: Truncation marker present"
  PASS=$(( PASS + 1 ))
else
  echo "  FAIL: Expected truncation marker"
  FAIL=$(( FAIL + 1 ))
fi

# Test 5: File context (glob)
mkdir -p src
echo "code" > src/main.ts
echo "test" > src/test.ts
collect_context --files "src/*.ts"
if [[ "$CONTEXT_FILE_COUNT" -gt 0 ]]; then
  echo "  PASS: Files found via glob"
  PASS=$(( PASS + 1 ))
else
  echo "  FAIL: No files found via glob (got $CONTEXT_FILE_COUNT)"
  FAIL=$(( FAIL + 1 ))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
