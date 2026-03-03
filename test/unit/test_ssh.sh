#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_HOME="$TEST_TEMP_DIR/home"
mkdir -p "$TEST_HOME/.ssh"

export HOME="$TEST_HOME"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/core/ssh.sh"

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

test_generate_ssh_key_creates_files() {
  local test_name="test_generate_ssh_key_creates_files"
  local test_key="test_key_$(date +%s)"
  
  generate_ssh_key "ed25519" "$test_key" "test@example.com" >/dev/null 2>&1
  
  if [[ -f "$HOME/.ssh/$test_key" && -f "$HOME/.ssh/$test_key.pub" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_generate_ssh_key_existing_file() {
  local test_name="test_generate_ssh_key_existing_file"
  local test_key="test_existing_key"
  
  generate_ssh_key "ed25519" "$test_key" "test@example.com" >/dev/null 2>&1
  
  if generate_ssh_key "ed25519" "$test_key" "test@example.com" >/dev/null 2>&1; then
    assert_fail "$test_name"
  else
    assert_pass "$test_name"
  fi
}

test_list_ssh_keys() {
  local test_name="test_list_ssh_keys"
  local output=$(list_ssh_keys)
  
  if [[ "$output" == *"SSH 密钥列表"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running SSH unit tests..."
echo "================================"

test_generate_ssh_key_creates_files
test_generate_ssh_key_existing_file
test_list_ssh_keys

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
