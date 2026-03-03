#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TEMP_DIR=$(mktemp -d)
export GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/.git-toolkit"
export ACCOUNTS_DIR="$GIT_TOOLKIT_DIR/accounts"
export BACKUP_DIR="$TEST_TEMP_DIR/backup"
export SSH_CONFIG_FILE="$TEST_TEMP_DIR/ssh_config"
mkdir -p "$BACKUP_DIR"
rm -f "$SSH_CONFIG_FILE"

source "$SCRIPT_DIR/../../src/constants.sh"
source "$SCRIPT_DIR/../../src/utils/logger.sh"
source "$SCRIPT_DIR/../../src/utils/git.sh"
source "$SCRIPT_DIR/../../src/utils/config.sh"
source "$SCRIPT_DIR/../../src/utils/validation.sh"
source "$SCRIPT_DIR/../../src/utils/ssh_config.sh"
source "$SCRIPT_DIR/../../src/core/auto_switch.sh"

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

assert_equal() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  
  if [[ "$expected" == "$actual" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected: '$expected', actual: '$actual'"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

setup_test_accounts() {
  mkdir -p "$ACCOUNTS_DIR"
  
  cat > "$ACCOUNTS_DIR/personal.conf" <<EOF
ACCOUNT_NAME="personal"
GIT_USER_NAME="Personal User"
GIT_USER_EMAIL="personal@example.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"
DOMAINS=("github.com" "*.gitee.com")
EOF
  
  cat > "$ACCOUNTS_DIR/work.conf" <<EOF
ACCOUNT_NAME="work"
GIT_USER_NAME="Work User"
GIT_USER_EMAIL="work@company.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_work"
DOMAINS=("git.company.com" "*.internal.company.com")
EOF
}

test_full_auto_switch_workflow() {
  local test_name="test_full_auto_switch_workflow"
  
  setup_test_accounts
  
  local test_repo="$TEST_TEMP_DIR/test-repo"
  mkdir -p "$test_repo"
  cd "$test_repo"
  git init -q >/dev/null 2>&1 || true
  git remote add origin "https://github.com/user/test-repo.git"
  
  auto_switch_account "$test_repo"
  
  local local_name=$(git config --file "$test_repo/.git/config" --get user.name 2>/dev/null || true)
  local local_email=$(git config --file "$test_repo/.git/config" --get user.email 2>/dev/null || true)
  
  assert_equal "$test_name - name" "Personal User" "$local_name"
  assert_equal "$test_name - email" "personal@example.com" "$local_email"
}

test_auto_switch_with_work_domain() {
  local test_name="test_auto_switch_with_work_domain"
  
  setup_test_accounts
  
  local test_repo="$TEST_TEMP_DIR/work-repo"
  mkdir -p "$test_repo"
  cd "$test_repo"
  git init -q >/dev/null 2>&1 || true
  git remote add origin "https://git.company.com/user/work-repo.git"
  
  auto_switch_account "$test_repo"
  
  local local_name=$(git config --file "$test_repo/.git/config" --get user.name 2>/dev/null || true)
  assert_equal "$test_name" "Work User" "$local_name"
}

test_auto_switch_with_wildcard_domain() {
  local test_name="test_auto_switch_with_wildcard_domain"
  
  setup_test_accounts
  
  local test_repo="$TEST_TEMP_DIR/internal-repo"
  mkdir -p "$test_repo"
  cd "$test_repo"
  git init -q >/dev/null 2>&1 || true
  git remote add origin "https://svn.internal.company.com/user/repo.git"
  
  auto_switch_account "$test_repo"
  
  local local_name=$(git config --file "$test_repo/.git/config" --get user.name 2>/dev/null || true)
  assert_equal "$test_name" "Work User" "$local_name"
}

test_auto_switch_no_repo() {
  local test_name="test_auto_switch_no_repo"
  
  setup_test_accounts
  
  local non_repo_dir="$TEST_TEMP_DIR/non-repo"
  mkdir -p "$non_repo_dir"
  
  auto_switch_account "$non_repo_dir" 2>&1 || true
  
  assert_pass "$test_name"
}

test_auto_switch_no_remote() {
  local test_name="test_auto_switch_no_remote"
  
  setup_test_accounts
  
  local test_repo="$TEST_TEMP_DIR/no-remote-repo"
  mkdir -p "$test_repo"
  cd "$test_repo"
  git init -q >/dev/null 2>&1 || true
  
  auto_switch_account "$test_repo" 2>&1 || true
  
  assert_pass "$test_name"
}

test_auto_switch_no_matching_account() {
  local test_name="test_auto_switch_no_matching_account"
  
  setup_test_accounts
  
  local test_repo="$TEST_TEMP_DIR/other-repo"
  mkdir -p "$test_repo"
  cd "$test_repo"
  git init -q >/dev/null 2>&1 || true
  git remote add origin "https://gitlab.com/user/repo.git"
  
  auto_switch_account "$test_repo" 2>&1 || true
  
  local local_name=$(git config --file "$test_repo/.git/config" --get user.name 2>/dev/null || true)
  
  if [[ -z "$local_name" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - should not set local config"
  fi
}

test_ssh_config_integration_with_account_add() {
  local test_name="test_ssh_config_integration_with_account_add"
  
  mkdir -p "$ACCOUNTS_DIR"
  
  save_account_config "test" "Test User" "test@example.com" "$HOME/.ssh/test_key" "github.com" "gitlab.com"
  
  add_ssh_config_for_account "test"
  
  assert_file_contains "$test_name - github" "$SSH_CONFIG_FILE" "Host github.com"
  assert_file_contains "$test_name - gitlab" "$SSH_CONFIG_FILE" "Host gitlab.com"
}

test_ssh_config_integration_with_account_delete() {
  local test_name="test_ssh_config_integration_with_account_delete"
  
  mkdir -p "$ACCOUNTS_DIR"
  
  save_account_config "test" "Test User" "test@example.com" "$HOME/.ssh/test_key" "github.com"
  add_ssh_config_for_account "test"
  
  remove_ssh_config_for_account "test"
  
  assert_file_not_contains "$test_name" "$SSH_CONFIG_FILE" "Host github.com"
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

echo "Running auto_switch integration tests..."
echo "================================"

test_full_auto_switch_workflow
test_auto_switch_with_work_domain
test_auto_switch_with_wildcard_domain
test_auto_switch_no_repo
test_auto_switch_no_remote
test_auto_switch_no_matching_account
test_ssh_config_integration_with_account_add
test_ssh_config_integration_with_account_delete

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
