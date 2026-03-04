#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_HOME="$TEST_TEMP_DIR/home"
TEST_ACCOUNTS_DIR="$TEST_TEMP_DIR/accounts"
TEST_SSH_CONFIG="$TEST_TEMP_DIR/ssh_config"
TEST_SSH_DIR="$TEST_TEMP_DIR/.ssh"
mkdir -p "$TEST_HOME"
mkdir -p "$TEST_ACCOUNTS_DIR"
mkdir -p "$TEST_SSH_DIR"

export HOME="$TEST_HOME"
export ACCOUNTS_DIR="$TEST_ACCOUNTS_DIR"
export SSH_CONFIG_FILE="$TEST_SSH_CONFIG"
export SSH_DIR="$TEST_SSH_DIR"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/utils/logger.sh"
source "$SCRIPT_DIR/../../src/utils/validation.sh"
source "$SCRIPT_DIR/../../src/utils/config.sh"
source "$SCRIPT_DIR/../../src/utils/ssh_config.sh"
source "$SCRIPT_DIR/../../src/core/ssh.sh"
source "$SCRIPT_DIR/../../src/core/account.sh"

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

assert_file_exists() {
  local test_name="$1"
  local file="$2"
  
  if [[ -f "$file" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file does not exist: $file"
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

test_add_account_creates_config_file() {
  local test_name="test_add_account_creates_config_file"
  
  add_account "personal" "Test User" "test@example.com" ""
  
  local config_file="$ACCOUNTS_DIR/personal.conf"
  assert_file_exists "$test_name" "$config_file"
}

test_add_account_with_ssh_key_and_domains() {
  local test_name="test_add_account_with_ssh_key_and_domains"
  
  touch "$TEST_SSH_DIR/test_key"
  
  add_account "work" "Work User" "work@example.com" "$TEST_SSH_DIR/test_key" "github.com"
  
  local config_file="$ACCOUNTS_DIR/work.conf"
  assert_file_contains "$test_name" "$config_file" "GIT_USER_NAME=\"Work User\""
  assert_file_contains "$test_name" "$config_file" "GIT_USER_EMAIL=\"work@example.com\""
  assert_file_contains "$test_name" "$config_file" "SSH_KEY_PATH=\"$TEST_SSH_DIR/test_key\""
  assert_file_contains "$test_name" "$config_file" "DOMAINS"
}

test_edit_account_updates_config() {
  local test_name="test_edit_account_updates_config"
  
  add_account "test" "Old User" "old@example.com" "" "github.com"
  
  edit_account "test" "New User" "new@example.com" "" '"github.com" "gitlab.com"'
  
  local config_file="$ACCOUNTS_DIR/test.conf"
  assert_file_contains "$test_name" "$config_file" "GIT_USER_NAME=\"New User\""
  assert_file_contains "$test_name" "$config_file" "GIT_USER_EMAIL=\"new@example.com\""
}

test_list_accounts_shows_accounts() {
  local test_name="test_list_accounts_shows_accounts"
  
  add_account "personal" "Test User" "test@example.com" ""
  
  local output=$(list_accounts)
  if [[ "$output" == *"personal"* ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_config_old_format_compatibility() {
  local test_name="test_config_old_format_compatibility"
  
  cat > "$ACCOUNTS_DIR/old_format.conf" <<EOF
ACCOUNT_NAME="old"
GIT_USER_NAME="Old User"
GIT_USER_EMAIL="old@example.com"
SSH_KEY_PATH="$TEST_SSH_DIR/old_key"
DOMAINS=("github.com" "gitlab.com")
EOF
  
  load_account_config "old_format"
  
  if [[ "$ACCOUNT_NAME" == "old" && "$GIT_USER_NAME" == "Old User" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_config_new_format_with_domain_ssh_keys() {
  local test_name="test_config_new_format_with_domain_ssh_keys"
  
  save_account_config_with_mapping "new_format" "New User" "new@example.com" "$TEST_SSH_DIR/default_key" '"github.com" "gitlab.com"' '"github.com:/test/path/github_key"'
  
  local config_file="$ACCOUNTS_DIR/new_format.conf"
  assert_file_contains "$test_name" "$config_file" "DOMAIN_SSH_KEYS"
  assert_file_contains "$test_name" "$config_file" "github.com:/test/path/github_key"
}

echo "Running account integration tests..."
echo "================================"

test_accounts_directory_created
test_username_validation
test_email_validation
test_add_account_creates_config_file
test_add_account_with_ssh_key_and_domains
test_edit_account_updates_config
test_list_accounts_shows_accounts
test_config_old_format_compatibility
test_config_new_format_with_domain_ssh_keys

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
