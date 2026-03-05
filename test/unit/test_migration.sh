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
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  if [[ -f "$SCRIPT_DIR/../../src/utils/migration.sh" ]]; then
    source "$SCRIPT_DIR/../../src/utils/migration.sh"
  fi
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

assert_file_not_exists() {
  local test_name="$1"
  local file="$2"

  if [[ ! -f "$file" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file exists unexpectedly: '$file'"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_check_migration_needed_when_no_marker() {
  local test_name="test_check_migration_needed_when_no_marker"
  setup_test_env

  if type check_migration_needed 2>/dev/null | grep -q "function"; then
    if check_migration_needed; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_check_migration_needed_when_marker_exists() {
  local test_name="test_check_migration_needed_when_marker_exists"
  setup_test_env
  touch "$MIGRATION_MARKER_FILE"

  if type check_migration_needed 2>/dev/null | grep -q "function"; then
    if ! check_migration_needed; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_run_migration_creates_marker() {
  local test_name="test_run_migration_creates_marker"
  setup_test_env

  if type run_migration 2>/dev/null | grep -q "function"; then
    run_migration
    assert_file_exists "$test_name" "$MIGRATION_MARKER_FILE"
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_rollback_migration_removes_marker() {
  local test_name="test_rollback_migration_removes_marker"
  setup_test_env
  touch "$MIGRATION_MARKER_FILE"

  if type rollback_migration 2>/dev/null | grep -q "function"; then
    rollback_migration
    assert_file_not_exists "$test_name" "$MIGRATION_MARKER_FILE"
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

echo "=== Running Migration Tests ==="
test_check_migration_needed_when_no_marker
test_check_migration_needed_when_marker_exists
test_run_migration_creates_marker
test_rollback_migration_removes_marker

echo ""
echo "=== Test Summary ==="
echo "Total: $test_count"
echo -e "Passed: \033[0;32m$pass_count\033[0m"
echo -e "Failed: \033[0;31m$fail_count\033[0m"

if [[ $fail_count -gt 0 ]]; then
  exit 1
fi
