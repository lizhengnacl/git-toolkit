#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_count=0
pass_count=0
fail_count=0

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/git-toolkit"
  mkdir -p "$GIT_TOOLKIT_DIR"
  
  export ACCOUNTS_DIR="$GIT_TOOLKIT_DIR/accounts"
  export SSH_CONFIG_FILE="$GIT_TOOLKIT_DIR/ssh_config"
  export SSH_DIR="$GIT_TOOLKIT_DIR/.ssh"
  export CONFIG_DIR="$GIT_TOOLKIT_DIR"
  mkdir -p "$ACCOUNTS_DIR"
  mkdir -p "$SSH_DIR"

  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  source "$SCRIPT_DIR/../../src/utils/migration.sh"
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

assert_file_exists() {
  local test_name="$1"
  local file="$2"

  if [[ -f "$file" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file does not exist: '$file'"
  fi
}

assert_file_contains() {
  local test_name="$1"
  local file="$2"
  local content="$3"
  
  if grep -qF "$content" "$file" 2>/dev/null; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file does not contain: '$content'"
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

test_migration_creates_marker() {
  local test_name="test_migration_creates_marker"
  setup_test_env
  
  if check_migration_needed; then
    assert_pass "$test_name - check_migration_needed returns true"
  else
    assert_fail "$test_name - check_migration_needed should return true"
  fi
  
  run_migration
  
  assert_file_exists "$test_name - marker created" "$MIGRATION_MARKER_FILE"
  
  if ! check_migration_needed; then
    assert_pass "$test_name - check_migration_needed returns false after migration"
  else
    assert_fail "$test_name - check_migration_needed should return false after migration"
  fi
}

test_rollback_removes_marker() {
  local test_name="test_rollback_removes_marker"
  setup_test_env
  
  run_migration
  
  assert_file_exists "$test_name - marker exists before rollback" "$MIGRATION_MARKER_FILE"
  
  rollback_migration
  
  if [[ ! -f "$MIGRATION_MARKER_FILE" ]]; then
    assert_pass "$test_name - marker removed"
  else
    assert_fail "$test_name - marker still exists"
  fi
}

echo "=== Running Migration Integration Tests ==="
test_migration_creates_marker
test_rollback_removes_marker

echo ""
echo "=== Test Summary ==="
echo "Total: $test_count"
echo -e "Passed: \033[0;32m$pass_count\033[0m"
echo -e "Failed: \033[0;31m$fail_count\033[0m"

if [[ $fail_count -gt 0 ]]; then
  exit 1
fi
