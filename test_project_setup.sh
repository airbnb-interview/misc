#!/bin/sh
# Usage: sh test_project_setup.sh
# Exit code: 0 if all tests pass, 1 if any fail.

PASS=0
FAIL=0

assert_equal() {
  label="$1"
  expected="$2"
  actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    echo "      expected: $expected"
    echo "      actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# Mirrors the exact guard condition from ai-coding-setup.sh.
project_note() {
  workdir="$1"
  if [ -d "$workdir/project" ] && [ -n "$(ls -A "$workdir/project" 2>/dev/null)" ]; then
    echo "existing project found"
  else
    echo "would proceed with setup"
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Case 1: no project directory -> setup should proceed
assert_equal \
  "no project dir: setup proceeds" \
  "would proceed with setup" \
  "$(project_note "$WORK")"

# Case 2: empty project directory -> setup should still proceed
mkdir "$WORK/project"
assert_equal \
  "empty project dir: setup proceeds" \
  "would proceed with setup" \
  "$(project_note "$WORK")"

# Case 3: non-empty project directory -> skip setup, reuse existing
echo "existing content" > "$WORK/project/file.txt"
assert_equal \
  "non-empty project dir: skip setup" \
  "existing project found" \
  "$(project_note "$WORK")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
