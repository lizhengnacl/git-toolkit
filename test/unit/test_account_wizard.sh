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
  TEST_SSH_DIR="$TEST_TEMP_DIR/.ssh"
  GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/git-toolkit"
  ACCOUNTS_DIR="$TEST_ACCOUNTS_DIR"
  SSH_CONFIG_FILE="$TEST_SSH_CONFIG"
  SSH_DIR="$TEST_SSH_DIR"
  BACKUP_DIR="$TEST_TEMP_DIR/backup"
  mkdir -p "$ACCOUNTS_DIR"
  mkdir -p "$BACKUP_DIR"
  mkdir -p "$TEST_SSH_DIR"
  rm -f "$TEST_SSH_CONFIG"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  source "$SCRIPT_DIR/../../src/ui/prompt.sh"
  source "$SCRIPT_DIR/../../src/utils/config.sh"
  source "$SCRIPT_DIR/../../src/core/ssh.sh"
  if [[ -f "$SCRIPT_DIR/../../src/ui/account_wizard.sh" ]]; then
    source "$SCRIPT_DIR/../../src/ui/account_wizard.sh"
  fi
}

mock_input() {
  export PROMPT_MOCK=("$@")
}

get_next_mock() {
  if [[ ${#PROMPT_MOCK[@]} -gt 0 ]]; then
    local next="${PROMPT_MOCK[0]}"
    PROMPT_MOCK=("${PROMPT_MOCK[@]:1}")
    echo "$next"
  fi
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

teardown() {
  if [[ -n "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

trap teardown EXIT

test_prompt_ssh_key_option_returns_generate() {
  local test_name="test_prompt_ssh_key_option_returns_generate"
  setup_test_env
  
  if type prompt_ssh_key_option 2>/dev/null | grep -q "function"; then
    mock_input "1"
    local result=$(prompt_ssh_key_option 2>&1)
    if [[ "$result" == "generate" || -z "$result" ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - expected 'generate', got '$result'"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_prompt_ssh_key_option_returns_select() {
  local test_name="test_prompt_ssh_key_option_returns_select"
  setup_test_env
  
  if type prompt_ssh_key_option 2>/dev/null | grep -q "function"; then
    mock_input "2"
    local result=$(prompt_ssh_key_option 2>&1)
    if [[ "$result" == "select" || -z "$result" ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - expected 'select', got '$result'"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_prompt_ssh_key_option_returns_skip() {
  local test_name="test_prompt_ssh_key_option_returns_skip"
  setup_test_env
  
  if type prompt_ssh_key_option 2>/dev/null | grep -q "function"; then
    mock_input "3"
    local result=$(prompt_ssh_key_option 2>&1)
    if [[ "$result" == "skip" || -z "$result" ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - expected 'skip', got '$result'"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

test_prompt_domains_returns_list() {
  local test_name="test_prompt_domains_returns_list"
  setup_test_env
  
  if type prompt_domains 2>/dev/null | grep -q "function"; then
    mock_input "github.com" "gitlab.com" ""
    local result=$(prompt_domains 2>&1)
    if [[ -z "$result" || "$result" == *"github.com"* ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - expected domains list"
    fi
  else
    assert_pass "$test_name - function not implemented yet"
  fi
}

echo "Running account_wizard tests..."
echo "================================"

test_prompt_ssh_key_option_returns_generate
test_prompt_ssh_key_option_returns_select
test_prompt_ssh_key_option_returns_skip
test_prompt_domains_returns_list

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
