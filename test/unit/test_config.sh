#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_count=0
pass_count=0
fail_count=0

setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  GIT_TOOLKIT_DIR="$TEST_TEMP_DIR/git-toolkit"
  mkdir -p "$GIT_TOOLKIT_DIR"
  
  source "$SCRIPT_DIR/../../src/constants.sh"
  source "$SCRIPT_DIR/../../src/utils/logger.sh"
  source "$SCRIPT_DIR/../../src/utils/config.sh"
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

assert_true() {
  local test_name="$1"
  local condition="$2"
  
  if eval "$condition"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

teardown() {
  if [[ -n "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

trap teardown EXIT

test_parse_domain_key_entry_simple() {
  local test_name="test_parse_domain_key_entry_simple"
  setup_test_env
  
  local entry="github.com:/home/user/.ssh/github_key"
  local domain=""
  local key_path=""
  
  if parse_domain_key_entry "$entry" domain key_path; then
    if [[ "$domain" == "github.com" && "$key_path" == "/home/user/.ssh/github_key" ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - expected domain: github.com, key: /home/user/.ssh/github_key, got domain: $domain, key: $key_path"
    fi
  else
    assert_fail "$test_name - parse failed"
  fi
}

test_parse_domain_key_entry_with_spaces() {
  local test_name="test_parse_domain_key_entry_with_spaces"
  setup_test_env
  
  local entry=" gitlab.com : /home/user/.ssh/gitlab key "
  local domain=""
  local key_path=""
  
  if parse_domain_key_entry "$entry" domain key_path; then
    if [[ "$domain" == "gitlab.com" && "$key_path" == "/home/user/.ssh/gitlab key" ]]; then
      assert_pass "$test_name"
    else
      assert_fail "$test_name - parse failed with spaces"
    fi
  else
    assert_fail "$test_name - parse failed"
  fi
}

test_parse_domain_key_entry_invalid() {
  local test_name="test_parse_domain_key_entry_invalid"
  setup_test_env
  
  local entry="invalid_entry"
  local domain=""
  local key_path=""
  
  if ! parse_domain_key_entry "$entry" domain key_path 2>/dev/null; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - should have failed for invalid entry"
  fi
}

test_build_domain_key_entry() {
  local test_name="test_build_domain_key_entry"
  setup_test_env
  
  local domain="github.com"
  local key_path="/home/user/.ssh/github_key"
  local entry=""
  
  entry=$(build_domain_key_entry "$domain" "$key_path")
  
  if [[ "$entry" == "github.com:/home/user/.ssh/github_key" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected: github.com:/home/user/.ssh/github_key, got: $entry"
  fi
}

test_extract_domains_from_config() {
  local test_name="test_extract_domains_from_config"
  setup_test_env
  
  local config_file="$TEST_TEMP_DIR/test.conf"
  cat > "$config_file" <<EOF
ACCOUNT_NAME="test"
GIT_USER_NAME="Test User"
GIT_USER_EMAIL="test@example.com"
DOMAINS=("github.com" "gitlab.com" "gitee.com")
EOF
  
  local -a domains=()
  extract_domains_from_config "$config_file" domains
  
  if [[ ${#domains[@]} -eq 3 && "${domains[0]}" == "github.com" && "${domains[1]}" == "gitlab.com" && "${domains[2]}" == "gitee.com" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - domain extraction failed"
  fi
}

test_get_key_for_domain_with_mapping() {
  local test_name="test_get_key_for_domain_with_mapping"
  setup_test_env
  
  local -a mappings=(
    "github.com:/home/user/.ssh/github_key"
    "gitlab.com:/home/user/.ssh/gitlab_key"
  )
  local default_key="/home/user/.ssh/default_key"
  
  local key=""
  get_key_for_domain "github.com" "$default_key" key "${mappings[@]}"
  
  if [[ "$key" == "/home/user/.ssh/github_key" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected mapped key, got: $key"
  fi
}

test_get_key_for_domain_without_mapping() {
  local test_name="test_get_key_for_domain_without_mapping"
  setup_test_env
  
  local -a mappings=(
    "github.com:/home/user/.ssh/github_key"
  )
  local default_key="/home/user/.ssh/default_key"
  
  local key=""
  get_key_for_domain "gitlab.com" "$default_key" key "${mappings[@]}"
  
  if [[ "$key" == "/home/user/.ssh/default_key" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected default key, got: $key"
  fi
}

echo "Running config tests..."
echo "================================"

test_parse_domain_key_entry_simple
test_parse_domain_key_entry_with_spaces
test_parse_domain_key_entry_invalid
test_build_domain_key_entry
test_extract_domains_from_config
test_get_key_for_domain_with_mapping
test_get_key_for_domain_without_mapping

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
