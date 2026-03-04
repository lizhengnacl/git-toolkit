#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEST_TEMP_DIR=$(mktemp -d)
TEST_HOME="$TEST_TEMP_DIR/home"
mkdir -p "$TEST_HOME"

export HOME="$TEST_HOME"

source "$SCRIPT_DIR/../../install.sh"

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
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

test_full_installation_flow_basic_check() {
  local test_name="test_full_installation_flow_basic_check"
  
  print_welcome_banner >/dev/null 2>&1
  detect_os_type >/dev/null 2>&1
  
  assert_true "$test_name" "[[ -n \"$OS_TYPE\" ]]"
}

test_existing_installation_detection_flow() {
  local test_name="test_existing_installation_detection_flow"
  
  mkdir -p "$INSTALL_DIR"
  
  if is_git_toolkit_installed; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_path_configuration_markers_present() {
  local test_name="test_path_configuration_markers_present"
  
  USER_SHELL="bash"
  SHELL_CONFIG_FILE="$TEST_HOME/.bashrc"
  touch "$SHELL_CONFIG_FILE"
  
  {
    echo ""
    echo "$PATH_CONFIG_START_MARKER"
    echo "export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
    echo "$PATH_CONFIG_END_MARKER"
  } >> "$SHELL_CONFIG_FILE"
  
  if is_path_already_configured; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

echo "Running install integration tests..."
echo "================================"

test_full_installation_flow_basic_check
test_existing_installation_detection_flow
test_path_configuration_markers_present

echo "================================"
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
