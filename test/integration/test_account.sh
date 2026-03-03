#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_HOME="$TEST_TEMP_DIR/home"
mkdir -p "$TEST_HOME"

export HOME="$TEST_HOME"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/utils/logger.sh"
source "$SCRIPT_DIR/../../src/utils/validation.sh"

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

test_accounts_directory_created() {
  local test_name="test_accounts_directory_created"
  mkdir -p "$ACCOUNTS_DIR"
  assert_true "$test_name" "[[ -d \"$ACCOUNTS_DIR\" ]]"
}

test_username_validation() {
  local test_name="test_username_validation"
  if validate_username "Test User"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_email_validation() {
  local test_name="test_email_validation"
  if validate_email "test@example.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running account integration tests..."
echo "================================"

test_accounts_directory_created
test_username_validation
test_email_validation

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
