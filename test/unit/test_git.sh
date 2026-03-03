#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_GIT_CONFIG="$TEST_TEMP_DIR/.gitconfig"
export GIT_CONFIG_GLOBAL="$TEST_GIT_CONFIG"

source "$SCRIPT_DIR/../../src/utils/git.sh"

test_count=0
pass_count=0
fail_count=0

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
  local expected="$2"
  local actual="$3"
  
  if [[ "$expected" == "$actual" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected: '$expected', actual: '$actual'"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_git_set_and_get_config() {
  local test_name="test_git_set_and_get_config"
  git_set_config "user.name" "Test User" "global"
  local actual=$(git_get_config "user.name" "global")
  assert_equal "$test_name" "Test User" "$actual"
}

test_git_has_config_true() {
  local test_name="test_git_has_config_true"
  git_set_config "user.email" "test@example.com" "global"
  if git_has_config "user.email" "global"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_git_has_config_false() {
  local test_name="test_git_has_config_false"
  if ! git_has_config "non.existent.key" "global"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_git_unset_config() {
  local test_name="test_git_unset_config"
  git_set_config "test.key" "value" "global"
  git_unset_config "test.key" "global"
  if ! git_has_config "test.key" "global"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running git tests..."
echo "================================"

test_git_set_and_get_config
test_git_has_config_true
test_git_has_config_false
test_git_unset_config

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
