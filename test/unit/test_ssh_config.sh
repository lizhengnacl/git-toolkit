#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/utils/ssh_config.sh"

test_count=0
pass_count=0
fail_count=0

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_SSH_CONFIG="$TEST_TEMP_DIR/ssh_config"
  TEST_ACCOUNTS_DIR="$TEST_TEMP_DIR/accounts"
  SSH_CONFIG_FILE="$TEST_SSH_CONFIG"
  ACCOUNTS_DIR="$TEST_ACCOUNTS_DIR"
  mkdir -p "$ACCOUNTS_DIR"
  rm -f "$TEST_SSH_CONFIG"
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
  
  if grep -qF "$content" "$file"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file does not contain: '$content'"
  fi
}

assert_file_not_contains() {
  local test_name="$1"
  local file="$2"
  local content="$3"
  
  if ! grep -qF "$content" "$file"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file contains unexpected content: '$content'"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_add_ssh_config_creates_markers() {
  local test_name="test_add_ssh_config_creates_markers"
  setup_test_env
  
  add_ssh_config "github.com" "$HOME/.ssh/id_ed25519"
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "$SSH_CONFIG_START_MARKER"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "$SSH_CONFIG_END_MARKER"
}

test_add_ssh_config_adds_host_entry() {
  local test_name="test_add_ssh_config_adds_host_entry"
  setup_test_env
  
  add_ssh_config "github.com" "$HOME/.ssh/id_ed25519"
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host github.com"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "IdentityFile $HOME/.ssh/id_ed25519"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "IdentitiesOnly yes"
}

test_add_ssh_config_supports_wildcard() {
  local test_name="test_add_ssh_config_supports_wildcard"
  setup_test_env
  
  add_ssh_config "*.company.com" "$HOME/.ssh/id_work"
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host *.company.com"
}

test_remove_ssh_config_removes_entry() {
  local test_name="test_remove_ssh_config_removes_entry"
  setup_test_env
  
  add_ssh_config "github.com" "$HOME/.ssh/id_ed25519"
  add_ssh_config "gitlab.com" "$HOME/.ssh/id_gitlab"
  remove_ssh_config "github.com"
  
  assert_file_not_contains "$test_name" "$TEST_SSH_CONFIG" "Host github.com"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host gitlab.com"
}

test_list_managed_ssh_config_lists_entries() {
  local test_name="test_list_managed_ssh_config_lists_entries"
  setup_test_env
  
  add_ssh_config "github.com" "$HOME/.ssh/id_ed25519"
  add_ssh_config "gitlab.com" "$HOME/.ssh/id_gitlab"
  
  local output=$(list_managed_ssh_config)
  if [[ "$output" == *"github.com"* && "$output" == *"gitlab.com"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - output missing entries"
  fi
}

test_rebuild_all_ssh_config_rebuilds() {
  local test_name="test_rebuild_all_ssh_config_rebuilds"
  setup_test_env
  
  mkdir -p "$ACCOUNTS_DIR"
  cat > "$ACCOUNTS_DIR/test.conf" <<EOF
ACCOUNT_NAME="test"
GIT_USER_NAME="Test"
GIT_USER_EMAIL="test@example.com"
SSH_KEY_PATH="$HOME/.ssh/test_key"
DOMAINS=("github.com" "gitlab.com")
EOF
  
  rebuild_all_ssh_config
  
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host github.com"
  assert_file_contains "$test_name" "$TEST_SSH_CONFIG" "Host gitlab.com"
}

echo "Running ssh_config tests..."
echo "================================"

test_add_ssh_config_creates_markers
test_add_ssh_config_adds_host_entry
test_add_ssh_config_supports_wildcard
test_remove_ssh_config_removes_entry
test_list_managed_ssh_config_lists_entries
test_rebuild_all_ssh_config_rebuilds

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
