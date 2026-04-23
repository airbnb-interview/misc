#!/bin/sh
# Usage: sh test_project_setup.sh
# Exit code: 0 if all tests pass, 1 if any fail.

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Source the real script without running main.
AI_CODING_SETUP_SOURCED=1
. "$SCRIPT_DIR/ai-coding-setup.sh"

# Stub git so the test doesn't need network or a real git install.
git() {
  if [ -n "${GIT_CALLS_FILE:-}" ]; then
    printf '%s\n' "$*" >> "$GIT_CALLS_FILE"
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
GIT_CALLS_FILE="$WORK/git-calls"

run_setup() {
  workdir="$1"
  lang_choice="$2"
  lang_name="$3"
  (
    WORKDIR="$workdir"
    LANG_CHOICE="$lang_choice"
    LANG_NAME="$lang_name"
    cd "$workdir"
    setup_project
    echo "$PROJECT_NOTE"
  )
}

# Case 1: no project directory -> setup proceeds
mkdir "$WORK/case1"
assert_equal \
  "no project dir: setup proceeds" \
  "empty git project initialized" \
  "$(run_setup "$WORK/case1" "1" "Python")"

# Case 2: empty project directory -> setup still proceeds
mkdir -p "$WORK/case2/project"
assert_equal \
  "empty project dir: setup proceeds" \
  "empty git project initialized" \
  "$(run_setup "$WORK/case2" "1" "Python")"

# Case 3: non-empty project directory -> skip, reuse existing
mkdir -p "$WORK/case3/project"
echo "existing content" > "$WORK/case3/project/file.txt"
assert_equal \
  "non-empty project dir: skip setup" \
  "existing project found" \
  "$(run_setup "$WORK/case3" "1" "Python")"

# Case 4: Java project -> clone Java starter
: > "$GIT_CALLS_FILE"
mkdir "$WORK/case4"
assert_equal \
  "java project: clone starter" \
  "empty Gradle project cloned" \
  "$(run_setup "$WORK/case4" "2" "Java")"
assert_equal \
  "java project: clone url" \
  "clone https://github.com/airbnb-interview/java-starter.git project" \
  "$(sed -n '1p' "$GIT_CALLS_FILE")"

# Case 5: Kotlin project -> clone Kotlin starter
: > "$GIT_CALLS_FILE"
mkdir "$WORK/case5"
assert_equal \
  "kotlin project: clone starter" \
  "empty Gradle project cloned" \
  "$(run_setup "$WORK/case5" "7" "Kotlin")"
assert_equal \
  "kotlin project: clone url" \
  "clone https://github.com/airbnb-interview/kotlin-starter.git project" \
  "$(sed -n '1p' "$GIT_CALLS_FILE")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
