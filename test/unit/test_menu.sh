#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_count=0
pass_count=0
fail_count=0

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)

  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  source "$SCRIPT_DIR/../../src/ui/menu.sh"
}

assert_pass() {
  local test_name="$1"
  test_count=$((test_count + 1))
  pass_count=$((pass_count + 1))
  echo -e "\033[0;32m[PASS]\033[0m $test_name"
}

assert_fail() {
  local test_name="$1"
  test_count=$((test_count + 1))
  fail_count=$((fail_count + 1))
  echo -e "\033[0;31m[FAIL]\033[0m $test_name"
}

assert_equal() {
  local test_name="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected: '$expected', actual: '$actual'"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
  unset GIT_TOOLKIT_EXPERT_MODE
}

trap teardown EXIT

test_is_expert_mode_when_not_set() {
  local test_name="test_is_expert_mode_when_not_set"
  setup_test_env
  unset GIT_TOOLKIT_EXPERT_MODE

  if ! is_expert_mode; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_is_expert_mode_when_false() {
  local test_name="test_is_expert_mode_when_false"
  setup_test_env
  export GIT_TOOLKIT_EXPERT_MODE=false

  if ! is_expert_mode; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_is_expert_mode_when_true() {
  local test_name="test_is_expert_mode_when_true"
  setup_test_env
  export GIT_TOOLKIT_EXPERT_MODE=true

  if is_expert_mode; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "=== Running Menu Tests ==="
test_is_expert_mode_when_not_set
test_is_expert_mode_when_false
test_is_expert_mode_when_true

echo ""
echo "=== Test Summary ==="
echo "Total: $test_count"
echo -e "Passed: \033[0;32m$pass_count\033[0m"
echo -e "Failed: \033[0;31m$fail_count\033[0m"

if [[ $fail_count -gt 0 ]]; then
  exit 1
fi
