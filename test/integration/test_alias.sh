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

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_alias_config_set() {
  local test_name="test_alias_config_set"
  git_set_config "alias.st" "status" "global"
  local value=$(git_get_config "alias.st" "global")
  if [[ "$value" == "status" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_default_aliases_exist() {
  local test_name="test_default_aliases_exist"
  if [[ ${#DEFAULT_ALIASES[@]} -gt 0 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running alias integration tests..."
echo "================================"

test_alias_config_set
test_default_aliases_exist

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
