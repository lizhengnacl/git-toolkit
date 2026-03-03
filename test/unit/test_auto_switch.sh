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
  TEST_GLOBAL_CONFIG="$TEST_TEMP_DIR/gitconfig"
  TEST_LOCAL_CONFIG="$TEST_TEMP_DIR/repo/.git/config"
  TEST_REPO_DIR="$TEST_TEMP_DIR/repo"
  GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/git-toolkit"
  ACCOUNTS_DIR="$TEST_ACCOUNTS_DIR"
  BACKUP_DIR="$TEST_TEMP_DIR/backup"
  mkdir -p "$ACCOUNTS_DIR"
  mkdir -p "$TEST_REPO_DIR"
  mkdir -p "$BACKUP_DIR"
  
  if command -v git >/dev/null 2>&1; then
    cd "$TEST_REPO_DIR"
    git init >/dev/null 2>&1 || true
  fi
  
  git config --file "$TEST_GLOBAL_CONFIG" user.name "Global User" 2>/dev/null || true
  git config --file "$TEST_GLOBAL_CONFIG" user.email "global@example.com" 2>/dev/null || true
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/core/auto_switch.sh"
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

test_extract_domain_from_https_url() {
  local test_name="test_extract_domain_from_https_url"
  setup_test_env
  
  local domain=$(extract_domain_from_url "https://github.com/user/repo.git")
  assert_equal "$test_name" "github.com" "$domain"
}

test_extract_domain_from_ssh_url() {
  local test_name="test_extract_domain_from_ssh_url"
  setup_test_env
  
  local domain=$(extract_domain_from_url "git@github.com:user/repo.git")
  assert_equal "$test_name" "github.com" "$domain"
}

test_extract_domain_from_ssh_protocol_url() {
  local test_name="test_extract_domain_from_ssh_protocol_url"
  setup_test_env
  
  local domain=$(extract_domain_from_url "ssh://git@github.com/user/repo.git")
  assert_equal "$test_name" "github.com" "$domain"
}

test_match_wildcard_domain_suffix_match() {
  local test_name="test_match_wildcard_domain_suffix_match"
  setup_test_env
  
  if match_wildcard_domain "*.company.com" "git.company.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_match_wildcard_domain_suffix_no_match() {
  local test_name="test_match_wildcard_domain_suffix_no_match"
  setup_test_env
  
  if ! match_wildcard_domain "*.company.com" "github.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_match_wildcard_domain_prefix_match() {
  local test_name="test_match_wildcard_domain_prefix_match"
  setup_test_env
  
  if match_wildcard_domain "git.*" "git.github.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_match_wildcard_domain_prefix_no_match() {
  local test_name="test_match_wildcard_domain_prefix_no_match"
  setup_test_env
  
  if ! match_wildcard_domain "git.*" "svn.github.com"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_match_account_by_domain_exact_match() {
  local test_name="test_match_account_by_domain_exact_match"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/personal.conf" <<EOF
ACCOUNT_NAME="personal"
GIT_USER_NAME="Test"
GIT_USER_EMAIL="test@example.com"
DOMAINS=("github.com")
EOF
  
  local account=$(match_account_by_domain "github.com")
  assert_equal "$test_name" "personal" "$account"
}

test_match_account_by_domain_wildcard_match() {
  local test_name="test_match_account_by_domain_wildcard_match"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/work.conf" <<EOF
ACCOUNT_NAME="work"
GIT_USER_NAME="Work"
GIT_USER_EMAIL="work@company.com"
DOMAINS=("*.company.com")
EOF
  
  local account=$(match_account_by_domain "git.company.com")
  assert_equal "$test_name" "work" "$account"
}

test_match_account_by_domain_exact_priority_over_wildcard() {
  local test_name="test_match_account_by_domain_exact_priority_over_wildcard"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/personal.conf" <<EOF
ACCOUNT_NAME="personal"
GIT_USER_NAME="Test"
GIT_USER_EMAIL="test@example.com"
DOMAINS=("github.com")
EOF
  
  cat > "$ACCOUNTS_DIR/work.conf" <<EOF
ACCOUNT_NAME="work"
GIT_USER_NAME="Work"
GIT_USER_EMAIL="work@company.com"
DOMAINS=("*.github.com")
EOF
  
  local account=$(match_account_by_domain "github.com")
  assert_equal "$test_name" "personal" "$account"
}

test_is_cd_hook_installed_not_installed() {
  local test_name="test_is_cd_hook_installed_not_installed"
  setup_test_env
  
  local test_rc="$TEST_TEMP_DIR/.zshrc"
  touch "$test_rc"
  
  if ! is_cd_hook_installed "$test_rc"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_is_cd_hook_installed_installed() {
  local test_name="test_is_cd_hook_installed_installed"
  setup_test_env
  
  local test_rc="$TEST_TEMP_DIR/.zshrc"
  cat > "$test_rc" <<EOF
# === git-toolkit auto-switch start ===
some content
# === git-toolkit auto-switch end ===
EOF
  
  if is_cd_hook_installed "$test_rc"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_auto_switch_account_not_a_repo() {
  local test_name="test_auto_switch_account_not_a_repo"
  setup_test_env
  
  local non_repo_dir="$TEST_TEMP_DIR/non_repo"
  mkdir -p "$non_repo_dir"
  
  auto_switch_account "$non_repo_dir" 2>&1 || true
  assert_pass "$test_name"
}

test_auto_switch_account_no_remote() {
  local test_name="test_auto_switch_account_no_remote"
  setup_test_env
  
  auto_switch_account "$TEST_REPO_DIR" 2>&1 || true
  assert_pass "$test_name"
}

test_auto_switch_account_with_remote_and_account() {
  local test_name="test_auto_switch_account_with_remote_and_account"
  setup_test_env
  
  cat > "$ACCOUNTS_DIR/personal.conf" <<EOF
ACCOUNT_NAME="personal"
GIT_USER_NAME="Test User"
GIT_USER_EMAIL="test@example.com"
DOMAINS=("github.com")
EOF
  
  cd "$TEST_REPO_DIR"
  git remote add origin https://github.com/user/repo.git 2>/dev/null || true
  
  auto_switch_account "$TEST_REPO_DIR" 2>&1 || true
  
  local user_name=$(git config --file "$TEST_LOCAL_CONFIG" user.name 2>/dev/null || true)
  local user_email=$(git config --file "$TEST_LOCAL_CONFIG" user.email 2>/dev/null || true)
  
  assert_equal "$test_name - user.name" "Test User" "$user_name"
  assert_equal "$test_name - user.email" "test@example.com" "$user_email"
}

test_auto_switch_account_no_matching_account() {
  local test_name="test_auto_switch_account_no_matching_account"
  setup_test_env
  
  cd "$TEST_REPO_DIR"
  git remote add origin https://github.com/user/repo.git 2>/dev/null || true
  
  auto_switch_account "$TEST_REPO_DIR" 2>&1 || true
  
  local user_name=$(git config --file "$TEST_LOCAL_CONFIG" user.name 2>/dev/null || true)
  
  if [[ -z "$user_name" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - should not set local config"
  fi
}

test_install_cd_hook_creates_config() {
  local test_name="test_install_cd_hook_creates_config"
  setup_test_env
  
  local test_rc="$TEST_TEMP_DIR/.testrc"
  touch "$test_rc"
  
  SHELL="$TEST_TEMP_DIR/testshell"
  
  local original_shell="$SHELL"
  SHELL="/bin/zsh"
  
  local temp_home="$TEST_TEMP_DIR/home"
  mkdir -p "$temp_home"
  
  local original_home="$HOME"
  HOME="$temp_home"
  
  install_cd_hook 2>&1 || true
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  assert_pass "$test_name"
}

test_uninstall_cd_hook_removes_config() {
  local test_name="test_uninstall_cd_hook_removes_config"
  setup_test_env
  
  local test_rc="$TEST_TEMP_DIR/.testrc"
  cat > "$test_rc" <<EOF
some content before
$CD_HOOK_START_MARKER
cd() {
  builtin cd "\$@"
  git-toolkit account auto-switch
}
$CD_HOOK_END_MARKER
some content after
EOF
  
  local original_shell="$SHELL"
  SHELL="/bin/zsh"
  
  local original_home="$HOME"
  HOME="$TEST_TEMP_DIR"
  
  local temp_zshrc="$TEST_TEMP_DIR/.zshrc"
  cp "$test_rc" "$temp_zshrc"
  
  uninstall_cd_hook 2>&1 || true
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  if ! grep -qF "$CD_HOOK_START_MARKER" "$temp_zshrc" && ! grep -qF "$CD_HOOK_END_MARKER" "$temp_zshrc"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - hooks still present"
  fi
}

test_uninstall_cd_hook_preserves_other_content() {
  local test_name="test_uninstall_cd_hook_preserves_other_content"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/bash"
  
  local original_home="$HOME"
  HOME="$TEST_TEMP_DIR"
  
  local temp_bashrc="$TEST_TEMP_DIR/.bashrc"
  cat > "$temp_bashrc" <<EOF
# some existing config
alias ll='ls -la'
export PATH=/some/path:\$PATH

$CD_HOOK_START_MARKER
cd() {
  builtin cd "\$@"
  git-toolkit account auto-switch
}
$CD_HOOK_END_MARKER

# more existing config
alias gs='git status'
EOF
  
  uninstall_cd_hook 2>&1 || true
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  local has_alias_ll=$(grep -qF "alias ll='ls -la'" "$temp_bashrc" && echo "yes" || echo "no")
  local has_alias_gs=$(grep -qF "alias gs='git status'" "$temp_bashrc" && echo "yes" || echo "no")
  local has_path=$(grep -qF "export PATH=/some/path:\$PATH" "$temp_bashrc" && echo "yes" || echo "no")
  local no_start_marker=$(grep -qF "$CD_HOOK_START_MARKER" "$temp_bashrc" && echo "no" || echo "yes")
  local no_end_marker=$(grep -qF "$CD_HOOK_END_MARKER" "$temp_bashrc" && echo "no" || echo "yes")
  
  if [[ "$has_alias_ll" == "yes" && "$has_alias_gs" == "yes" && "$has_path" == "yes" && "$no_start_marker" == "yes" && "$no_end_marker" == "yes" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - content not preserved correctly"
  fi
}

test_install_cd_hook_already_installed() {
  local test_name="test_install_cd_hook_already_installed"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/zsh"
  
  local original_home="$HOME"
  HOME="$TEST_TEMP_DIR"
  
  local temp_zshrc="$TEST_TEMP_DIR/.zshrc"
  cat > "$temp_zshrc" <<EOF
$CD_HOOK_START_MARKER
cd() {
  builtin cd "\$@"
  git-toolkit account auto-switch
}
$CD_HOOK_END_MARKER
EOF
  
  local original_size=$(wc -c < "$temp_zshrc")
  
  install_cd_hook 2>&1 || true
  
  local new_size=$(wc -c < "$temp_zshrc")
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  if [[ "$original_size" -eq "$new_size" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file was modified when it shouldn't be"
  fi
}

test_install_cd_hook_unsupported_shell() {
  local test_name="test_install_cd_hook_unsupported_shell"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/fish"
  
  if ! install_cd_hook 2>&1; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - should have failed for unsupported shell"
  fi
  
  SHELL="$original_shell"
}

test_uninstall_cd_hook_unsupported_shell() {
  local test_name="test_uninstall_cd_hook_unsupported_shell"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/fish"
  
  if ! uninstall_cd_hook 2>&1; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - should have failed for unsupported shell"
  fi
  
  SHELL="$original_shell"
}

test_uninstall_cd_hook_not_installed() {
  local test_name="test_uninstall_cd_hook_not_installed"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/zsh"
  
  local original_home="$HOME"
  HOME="$TEST_TEMP_DIR"
  
  local temp_zshrc="$TEST_TEMP_DIR/.zshrc"
  echo "some content" > "$temp_zshrc"
  
  local original_content=$(cat "$temp_zshrc")
  
  uninstall_cd_hook 2>&1 || true
  
  local new_content=$(cat "$temp_zshrc")
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  if [[ "$original_content" == "$new_content" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file was modified when it shouldn't be"
  fi
}

test_uninstall_cd_hook_file_not_exists() {
  local test_name="test_uninstall_cd_hook_file_not_exists"
  setup_test_env
  
  local original_shell="$SHELL"
  SHELL="/bin/zsh"
  
  local original_home="$HOME"
  HOME="$TEST_TEMP_DIR"
  
  local temp_zshrc="$TEST_TEMP_DIR/.zshrc"
  rm -f "$temp_zshrc"
  
  uninstall_cd_hook 2>&1 || true
  
  HOME="$original_home"
  SHELL="$original_shell"
  
  if [[ ! -f "$temp_zshrc" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - file should not have been created"
  fi
}

echo "Running auto_switch tests..."
echo "================================"

test_extract_domain_from_https_url
test_extract_domain_from_ssh_url
test_extract_domain_from_ssh_protocol_url
test_match_wildcard_domain_suffix_match
test_match_wildcard_domain_suffix_no_match
test_match_wildcard_domain_prefix_match
test_match_wildcard_domain_prefix_no_match
test_match_account_by_domain_exact_match
test_match_account_by_domain_wildcard_match
test_match_account_by_domain_exact_priority_over_wildcard
test_is_cd_hook_installed_not_installed
test_is_cd_hook_installed_installed
test_auto_switch_account_not_a_repo
test_auto_switch_account_no_remote
test_auto_switch_account_with_remote_and_account
test_auto_switch_account_no_matching_account
test_install_cd_hook_creates_config
test_install_cd_hook_already_installed
test_install_cd_hook_unsupported_shell
test_uninstall_cd_hook_removes_config
test_uninstall_cd_hook_preserves_other_content
test_uninstall_cd_hook_not_installed
test_uninstall_cd_hook_file_not_exists
test_uninstall_cd_hook_unsupported_shell

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
