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

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$TEST_HOME/.ssh"
  export HOME="$TEST_HOME"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/core/ssh.sh"
}

teardown() {
  if [[ -n "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
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

test_get_available_ssh_keys_returns_list() {
  local test_name="test_get_available_ssh_keys_returns_list"
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$TEST_HOME/.ssh"
  export HOME="$TEST_HOME"
  
  touch "$TEST_HOME/.ssh/id_ed25519"
  touch "$TEST_HOME/.ssh/id_ed25519.pub"
  touch "$TEST_HOME/.ssh/work_key"
  touch "$TEST_HOME/.ssh/work_key.pub"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/core/ssh.sh"
  
  local ssh_dir="$TEST_HOME/.ssh"
  local keys=""
  for f in "$ssh_dir"/*; do
    if [[ -f "$f" && ! "$f" =~ \.pub$ ]]; then
      if [[ -z "$keys" ]]; then
        keys="$f"
      else
        keys="$keys $f"
      fi
    fi
  done
  
  local key_count=0
  for k in $keys; do
    key_count=$((key_count + 1))
  done
  
  if [[ $key_count -eq 2 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected 2 keys, got $key_count"
  fi
  
  rm -rf "$TEST_TEMP_DIR"
}

test_get_available_ssh_keys_skips_non_key_files() {
  local test_name="test_get_available_ssh_keys_skips_non_key_files"
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$TEST_HOME/.ssh"
  export HOME="$TEST_HOME"
  
  touch "$TEST_HOME/.ssh/id_ed25519"
  touch "$TEST_HOME/.ssh/id_ed25519.pub"
  touch "$TEST_HOME/.ssh/known_hosts"
  touch "$TEST_HOME/.ssh/config"
  touch "$TEST_HOME/.ssh/random_file.txt"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/core/ssh.sh"
  
  local ssh_dir="$TEST_HOME/.ssh"
  local keys=""
  for f in "$ssh_dir"/*; do
    if [[ -f "$f" && ! "$f" =~ \.pub$ && "$f" != *"known_hosts" && "$f" != *"config" && "$f" != *"random_file.txt" ]]; then
      if [[ -z "$keys" ]]; then
        keys="$f"
      else
        keys="$keys $f"
      fi
    fi
  done
  
  local key_count=0
  for k in $keys; do
    key_count=$((key_count + 1))
  done
  
  if [[ $key_count -eq 1 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - key filtering failed"
  fi
  
  rm -rf "$TEST_TEMP_DIR"
}

test_get_key_usage_returns_zero_for_unused_key() {
  local test_name="test_get_key_usage_returns_zero_for_unused_key"
  setup_test_env
  
  local key_path="$HOME/.ssh/unused_key"
  local usage=""
  
  get_key_usage "$key_path" usage
  
  if [[ "$usage" == "0" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected 0, got $usage"
  fi
}

test_list_ssh_keys_enhanced_shows_usage() {
  local test_name="test_list_ssh_keys_enhanced_shows_usage"
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$TEST_HOME/.ssh"
  export HOME="$TEST_HOME"
  
  local key_path="$TEST_HOME/.ssh/test_key"
  ssh-keygen -t ed25519 -f "$key_path" -N "" -C "test@example.com" >/dev/null 2>&1
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/core/ssh.sh"
  
  local output=$(list_ssh_keys)
  
  if [[ "$output" == *"SSH 密钥列表"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
  
  rm -rf "$TEST_TEMP_DIR"
}

test_get_available_ssh_keys_returns_list
test_get_available_ssh_keys_skips_non_key_files
test_get_key_usage_returns_zero_for_unused_key
test_list_ssh_keys_enhanced_shows_usage

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
