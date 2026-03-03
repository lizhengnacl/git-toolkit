#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

test_validate_email_valid() {
  local test_name="test_validate_email_valid"
  
  if validate_email "test@example.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_email_invalid() {
  local test_name="test_validate_email_invalid"
  
  if ! validate_email "invalid-email"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_username_valid() {
  local test_name="test_validate_username_valid"
  
  if validate_username "张三"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_username_empty() {
  local test_name="test_validate_username_empty"
  
  if ! validate_username ""; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_domain_valid() {
  local test_name="test_validate_domain_valid"
  
  if validate_domain "github.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_domain_invalid() {
  local test_name="test_validate_domain_invalid"
  
  if ! validate_domain "invalid..domain"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_path_safe() {
  local test_name="test_validate_path_safe"
  
  if validate_path "some/path"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_path_unsafe_parent() {
  local test_name="test_validate_path_unsafe_parent"
  
  if ! validate_path "../path"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_validate_path_unsafe_absolute() {
  local test_name="test_validate_path_unsafe_absolute"
  
  if ! validate_path "/absolute/path"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running validation tests..."
echo "================================"

test_validate_email_valid
test_validate_email_invalid
test_validate_username_valid
test_validate_username_empty
test_validate_domain_valid
test_validate_domain_invalid
test_validate_path_safe
test_validate_path_unsafe_parent
test_validate_path_unsafe_absolute

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
