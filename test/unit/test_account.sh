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

test_load_account_config_supports_old_format() {
  local test_name="test_load_account_config_supports_old_format"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/old_format.conf" <<EOF
ACCOUNT_NAME="old"
GIT_USER_NAME="Old User"
GIT_USER_EMAIL="old@example.com"
SSH_KEY_PATH="$HOME/.ssh/old_key"
DOMAINS=("github.com" "gitlab.com")
EOF
  
  load_account_config "old_format"
  
  if [[ "$ACCOUNT_NAME" == "old" && "$GIT_USER_NAME" == "Old User" && "$GIT_USER_EMAIL" == "old@example.com" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_save_account_config_supports_domain_ssh_keys() {
  local test_name="test_save_account_config_supports_domain_ssh_keys"
  setup_test_env
  
  save_account_config_with_mapping "new_format" "New User" "new@example.com" "$HOME/.ssh/default_key" '"github.com" "gitlab.com" "gitee.com"' '"github.com:$HOME/.ssh/github_key" "gitlab.com:$HOME/.ssh/gitlab_key"'
  
  local config_file="$ACCOUNTS_DIR/new_format.conf"
  
  assert_file_contains "$test_name" "$config_file" "DOMAIN_SSH_KEYS"
}

test_list_accounts_shows_default_key_and_mappings() {
  local test_name="test_list_accounts_shows_default_key_and_mappings"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/test.conf" <<EOF
ACCOUNT_NAME="test"
GIT_USER_NAME="Test User"
GIT_USER_EMAIL="test@example.com"
SSH_KEY_PATH="$HOME/.ssh/default_key"
DOMAINS=("github.com" "gitlab.com")
DOMAIN_SSH_KEYS=("github.com:$HOME/.ssh/github_key")
EOF
  
  local output=$(list_accounts)
  
  if [[ "$output" == *"SSH 密钥"* && "$output" == *"github.com"* && "$output" == *"github_key"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_edit_account_updates_config() {
  local test_name="test_edit_account_updates_config"
  setup_test_env
  
  add_account "test" "Old User" "old@example.com" "$HOME/.ssh/old_key" "github.com"
  
  edit_account "test" "New User" "new@example.com" "$HOME/.ssh/new_key" '"github.com" "gitlab.com"' '"github.com:$HOME/.ssh/github_key"'
  
  local config_file="$ACCOUNTS_DIR/test.conf"
  
  assert_file_contains "$test_name" "$config_file" "GIT_USER_NAME=\"New User\""
  assert_file_contains "$test_name" "$config_file" "GIT_USER_EMAIL=\"new@example.com\""
  assert_file_contains "$test_name" "$config_file" "SSH_KEY_PATH=\"$HOME/.ssh/new_key\""
}

test_is_key_used_by_others_when_not_used() {
  local test_name="test_is_key_used_by_others_when_not_used"
  setup_test_env
  
  add_account "test1" "User 1" "user1@example.com" "$HOME/.ssh/key1" "github.com"
  
  if ! is_key_used_by_others "test1" "$HOME/.ssh/key1"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_is_key_used_by_others_when_used_by_other() {
  local test_name="test_is_key_used_by_others_when_used_by_other"
  setup_test_env
  
  add_account "test1" "User 1" "user1@example.com" "$HOME/.ssh/shared_key" "github.com"
  add_account "test2" "User 2" "user2@example.com" "$HOME/.ssh/shared_key" "gitlab.com"
  
  if is_key_used_by_others "test1" "$HOME/.ssh/shared_key"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_show_public_key_returns_content() {
  local test_name="test_show_public_key_returns_content"
  setup_test_env
  
  local test_key_dir="$TEST_TEMP_DIR/ssh"
  mkdir -p "$test_key_dir"
  local private_key="$test_key_dir/test_key"
  local public_key="$test_key_dir/test_key.pub"
  
  cat > "$private_key" <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACB0ZXN0a2V5dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQAAAAKQAAAA
WAAAAAtzc2gtZWQyNTUxOQAAACB0ZXN0a2V5dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdG
tleQAAAAEAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQIDBAUGBwg=
-----END OPENSSH PRIVATE KEY-----
EOF
  
  local expected_public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRlc3RrZXl0ZXN0a2V5dGVzdGtleXRlc3RrZXl0ZXN0a2V5 test@example.com"
  echo "$expected_public_key" > "$public_key"
  
  local result=$(show_public_key "$private_key")
  if [[ "$result" == "$expected_public_key" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected: '$expected_public_key', got: '$result'"
  fi
}

test_delete_account_preserves_ssh_key_by_default() {
  local test_name="test_delete_account_preserves_ssh_key_by_default"
  setup_test_env
  
  local test_key_dir="$TEST_TEMP_DIR/ssh"
  mkdir -p "$test_key_dir"
  local private_key="$test_key_dir/test_key"
  local public_key="$test_key_dir/test_key.pub"
  
  touch "$private_key"
  touch "$public_key"
  
  add_account "test" "Test User" "test@example.com" "$private_key" "github.com"
  
  delete_account "test"
  
  assert_file_exists "$test_name" "$private_key"
  assert_file_exists "$test_name" "$public_key"
}

test_delete_account_deletes_ssh_key_when_specified() {
  local test_name="test_delete_account_deletes_ssh_key_when_specified"
  setup_test_env
  
  local test_key_dir="$TEST_TEMP_DIR/ssh"
  mkdir -p "$test_key_dir"
  local private_key="$test_key_dir/test_key"
  local public_key="$test_key_dir/test_key.pub"
  
  touch "$private_key"
  touch "$public_key"
  
  add_account "test" "Test User" "test@example.com" "$private_key" "github.com"
  
  delete_account "test" "true"
  
  assert_file_not_exists "$test_name" "$private_key"
  assert_file_not_exists "$test_name" "$public_key"
}

test_load_account_config_supports_old_format
test_save_account_config_supports_domain_ssh_keys
test_list_accounts_shows_default_key_and_mappings
test_edit_account_updates_config
test_is_key_used_by_others_when_not_used
test_is_key_used_by_others_when_used_by_other
test_show_public_key_returns_content
test_delete_account_preserves_ssh_key_by_default
test_delete_account_deletes_ssh_key_when_specified

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
