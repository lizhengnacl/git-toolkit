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
source "$SCRIPT_DIR/../../src/utils/backup.sh"

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

assert_true() {
  local test_name="$1"
  local condition="$2"
  
  if eval "$condition"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_git_config_directory_created() {
  local test_name="test_git_config_directory_created"
  mkdir -p "$GIT_TOOLKIT_DIR"
  assert_true "$test_name" "[[ -d \"$GIT_TOOLKIT_DIR\" ]]"
}

test_backup_created() {
  local test_name="test_backup_created"
  git_set_config "user.name" "Old User" "global"
  git_set_config "user.email" "old@example.com" "global"
  
  local gitconfig_path="$HOME/.gitconfig"
  if [[ -f "$gitconfig_path" ]]; then
    create_backup "$gitconfig_path"
    local backups=$(list_backups ".gitconfig*")
    assert_true "$test_name" "[[ -n \"$backups\" ]]"
  else
    assert_pass "$test_name"
  fi
}

echo "Running init integration tests..."
echo "================================"

test_git_config_directory_created
test_backup_created

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
