#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_count=0
pass_count=0
fail_count=0

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_ACCOUNTS_DIR="$TEST_TEMP_DIR/accounts"
  TEST_SSH_CONFIG="$TEST_TEMP_DIR/ssh_config"
  GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/git-toolkit"
  ACCOUNTS_DIR="$TEST_ACCOUNTS_DIR"
  SSH_CONFIG_FILE="$TEST_SSH_CONFIG"
  BACKUP_DIR="$TEST_TEMP_DIR/backup"
  mkdir -p "$ACCOUNTS_DIR"
  mkdir -p "$BACKUP_DIR"
  rm -f "$TEST_SSH_CONFIG"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  source "$SCRIPT_DIR/../../src/utils/git.sh"
  source "$SCRIPT_DIR/../../src/utils/config.sh"
  source "$SCRIPT_DIR/../../src/utils/validation.sh"
  source "$SCRIPT_DIR/../../src/utils/ssh_config.sh"
  source "$SCRIPT_DIR/../../src/core/account.sh"
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

assert_file_not_contains() {
  local test_name="$1"
  local file="$2"
  local content="$3"
  
  if ! grep -qF "$content" "$file" 2>/dev/null; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file contains unexpected content: '$content'"
  fi
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

test_add_account_creates_config_file() {
  local test_name="test_add_account_creates_config_file"
  setup_test_env
  
  add_account "personal" "Test User" "test@example.com" "" "github.com"
  
  local config_file="$ACCOUNTS_DIR/personal.conf"
  assert_file_exists "$test_name" "$config_file"
}

test_add_account_with_ssh_key_adds_ssh_config() {
  local test_name="test_add_account_with_ssh_key_adds_ssh_config"
  setup_test_env
  
  add_account "work" "Work User" "work@company.com" "$HOME/.ssh/work_key" "git.company.com"
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host git.company.com"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "IdentityFile $HOME/.ssh/work_key"
}

test_add_account_with_multiple_domains_adds_all_ssh_config() {
  local test_name="test_add_account_with_multiple_domains_adds_all_ssh_config"
  setup_test_env
  
  add_account "personal" "Test User" "test@example.com" "$HOME/.ssh/personal_key" "github.com" "gitlab.com"
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host github.com"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host gitlab.com"
}

test_delete_account_removes_ssh_config() {
  local test_name="test_delete_account_removes_ssh_config"
  setup_test_env
  
  add_account "personal" "Test User" "test@example.com" "$HOME/.ssh/personal_key" "github.com"
  delete_account "personal"
  
  assert_file_not_exists "$test_name" "$ACCOUNTS_DIR/personal.conf"
  assert_file_not_contains "$test_name" "$TEST_SSH_CONFIG" "Host github.com"
}

test_list_accounts_shows_domains() {
  local test_name="test_list_accounts_shows_domains"
  setup_test_env
  
  add_account "personal" "Test User" "test@example.com" "$HOME/.ssh/personal_key" "github.com" "gitlab.com"
  
  local output=$(list_accounts)
  if [[ "$output" == *"github.com"* || "$output" == *"gitlab.com"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - output missing domains"
  fi
}

echo "Running account tests..."
echo "================================"

test_add_account_creates_config_file
test_add_account_with_ssh_key_adds_ssh_config
test_add_account_with_multiple_domains_adds_all_ssh_config
test_delete_account_removes_ssh_config
test_list_accounts_shows_domains

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
