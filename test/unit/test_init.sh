#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_HOME="$TEST_TEMP_DIR/home"
mkdir -p "$TEST_HOME"

export HOME="$TEST_HOME"
export GIT_CONFIG_GLOBAL="$TEST_HOME/.gitconfig"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/utils/git.sh"
source "$SCRIPT_DIR/../../src/core/init.sh"

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

test_configure_git_settings() {
  local test_name="test_configure_git_settings"
  configure_git_settings "Test User" "test@example.com"
  
  local name=$(git_get_config "user.name" "global")
  local email=$(git_get_config "user.email" "global")
  
  if [[ "$name" == "Test User" && "$email" == "test@example.com" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_apply_default_aliases() {
  local test_name="test_apply_default_aliases"
  apply_default_aliases
  
  local all_present=true
  for alias in "${DEFAULT_ALIASES[@]}"; do
    local name="${alias%%=*}"
    local value=$(git_get_config "alias.$name" "global")
    if [[ -z "$value" ]]; then
      all_present=false
      break
    fi
  done
  
  if $all_present; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_init_git_environment() {
  local test_name="test_init_git_environment"
  init_git_environment "Init Test User" "init@example.com"
  
  local name=$(git_get_config "user.name" "global")
  local email=$(git_get_config "user.email" "global")
  local toolkit_dir_exists=false
  if [[ -d "$GIT_TOOLKIT_DIR" ]]; then
    toolkit_dir_exists=true
  fi
  
  if [[ "$name" == "Init Test User" && "$email" == "init@example.com" && $toolkit_dir_exists == true ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running init unit tests..."
echo "================================"

test_configure_git_settings
test_apply_default_aliases
test_init_git_environment

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
