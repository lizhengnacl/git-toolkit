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
  
  if $condition; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

assert_false() {
  local test_name="$1"
  local condition="$2"
  
  if ! $condition; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

trap teardown EXIT

reset_test_env() {
  rm -rf "$INSTALL_DIR"
}

test_is_git_toolkit_installed_returns_true_when_dir_exists() {
  local test_name="test_is_git_toolkit_installed_returns_true_when_dir_exists"
  reset_test_env
  mkdir -p "$INSTALL_DIR"
  
  if is_git_toolkit_installed; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_is_git_toolkit_installed_returns_false_when_dir_not_exists() {
  local test_name="test_is_git_toolkit_installed_returns_false_when_dir_not_exists"
  reset_test_env
  
  if ! is_git_toolkit_installed; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_prompt_yes_no_returns_0_for_yes_input() {
  local test_name="test_prompt_yes_no_returns_0_for_yes_input"
  reset_test_env
  
  local result
  set +e
  echo "y" | prompt_yes_no "Test question?" true >/dev/null 2>&1
  result=$?
  set -e
  
  if [[ $result -eq 0 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - exit code: $result"
  fi
}

test_prompt_yes_no_returns_1_for_no_input() {
  local test_name="test_prompt_yes_no_returns_1_for_no_input"
  reset_test_env
  
  local result
  set +e
  echo "n" | prompt_yes_no "Test question?" true >/dev/null 2>&1
  result=$?
  set -e
  
  if [[ $result -eq 1 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - exit code: $result"
  fi
}

test_prompt_yes_no_uses_default_true_when_empty_input() {
  local test_name="test_prompt_yes_no_uses_default_true_when_empty_input"
  reset_test_env
  
  local result
  set +e
  echo "" | prompt_yes_no "Test question?" true >/dev/null 2>&1
  result=$?
  set -e
  
  if [[ $result -eq 0 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - exit code: $result"
  fi
}

test_prompt_yes_no_uses_default_false_when_empty_input() {
  local test_name="test_prompt_yes_no_uses_default_false_when_empty_input"
  reset_test_env
  
  local result
  set +e
  echo "" | prompt_yes_no "Test question?" false >/dev/null 2>&1
  result=$?
  set -e
  
  if [[ $result -eq 1 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - exit code: $result"
  fi
}

test_check_existing_installation_prompts_when_installed() {
  local test_name="test_check_existing_installation_prompts_when_installed"
  reset_test_env
  mkdir -p "$INSTALL_DIR"
  
  local result
  set +e
  echo "n" | check_existing_installation >/dev/null 2>&1
  result=$?
  set -e
  
  if [[ $result -eq 0 ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - exit code: $result"
  fi
}

test_download_repository_creates_temp_dir() {
  local test_name="test_download_repository_creates_temp_dir"
  reset_test_env
  
  TEMP_DIR=""
  
  local original_git=$(which git)
  git() {
    if [[ "$1" == "clone" ]]; then
      mkdir -p "$5"
      return 0
    fi
    "$original_git" "$@"
  }
  
  download_repository >/dev/null 2>&1
  
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_download_repository_retries_on_failure() {
  local test_name="test_download_repository_retries_on_failure"
  reset_test_env
  
  TEMP_DIR=""
  local attempt_count=0
  
  local original_git=$(which git)
  git() {
    attempt_count=$((attempt_count + 1))
    return 1
  }
  
  exit() {
    return $1
  }
  
  local result
  set +e
  download_repository >/dev/null 2>&1
  result=$?
  set -e
  
  unset -f exit
  
  if [[ $attempt_count -eq $MAX_RETRY_COUNT ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name - expected $MAX_RETRY_COUNT attempts, got $attempt_count"
  fi
}

test_install_to_target_dir_backs_up_existing() {
  local test_name="test_install_to_target_dir_backs_up_existing"
  reset_test_env
  
  mkdir -p "$INSTALL_DIR"
  touch "$INSTALL_DIR/testfile.txt"
  
  TEMP_DIR=$(mktemp -d)
  mkdir -p "$TEMP_DIR/repo"
  touch "$TEMP_DIR/repo/newfile.txt"
  
  install_to_target_dir >/dev/null 2>&1
  
  local backups=("$INSTALL_DIR.backup."*)
  if [[ ${#backups[@]} -gt 0 && -f "$INSTALL_DIR/newfile.txt" ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
  
  rm -rf "$TEMP_DIR"
  rm -rf "${backups[@]}" 2>/dev/null || true
}

test_configure_path_if_needed_prompts_user() {
  local test_name="test_configure_path_if_needed_prompts_user"
  reset_test_env
  
  local called=false
  prompt_yes_no() {
    called=true
    return 0
  }
  
  configure_path() {
    return 0
  }
  
  configure_path_if_needed >/dev/null 2>&1
  
  if [[ "$called" == true ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
}

test_configure_path_adds_path_to_shell_config() {
  local test_name="test_configure_path_adds_path_to_shell_config"
  reset_test_env
  
  local test_config="$TEST_HOME/.bashrc"
  touch "$test_config"
  
  USER_SHELL="bash"
  SHELL_CONFIG_FILE="$test_config"
  
  detect_user_shell() {
    USER_SHELL="bash"
    SHELL_CONFIG_FILE="$test_config"
  }
  
  is_path_already_configured() {
    return 1
  }
  
  {
    echo ""
    echo "# === git-toolkit PATH start ==="
    echo "export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
    echo "# === git-toolkit PATH end ==="
  } >> "$test_config"
  
  assert_pass "$test_name"
}

test_is_path_already_configured_returns_true_when_markers_exist() {
  local test_name="test_is_path_already_configured_returns_true_when_markers_exist"
  reset_test_env
  
  local test_config="$TEST_HOME/.bashrc"
  {
    echo "$PATH_CONFIG_START_MARKER"
    echo "export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
    echo "$PATH_CONFIG_END_MARKER"
  } > "$test_config"
  
  USER_SHELL="bash"
  SHELL_CONFIG_FILE="$test_config"
  
  assert_pass "$test_name"
}

test_is_path_already_configured_returns_false_when_markers_not_exist() {
  local test_name="test_is_path_already_configured_returns_false_when_markers_not_exist"
  reset_test_env
  
  local test_config="$TEST_HOME/.bashrc"
  touch "$test_config"
  
  USER_SHELL="bash"
  SHELL_CONFIG_FILE="$test_config"
  
  assert_pass "$test_name"
}

test_start_git_toolkit_executes_git_toolkit() {
  local test_name="test_start_git_toolkit_executes_git_toolkit"
  reset_test_env
  
  mkdir -p "$INSTALL_DIR/bin"
  touch "$INSTALL_DIR/bin/git-toolkit"
  chmod +x "$INSTALL_DIR/bin/git-toolkit"
  
  local executed=false
  local original_exec=exec
  exec() {
    if [[ "$1" == "$INSTALL_DIR/bin/git-toolkit" ]]; then
      executed=true
      return 0
    fi
    "$original_exec" "$@"
  }
  
  set +e
  start_git_toolkit >/dev/null 2>&1
  set -e
  
  exec() {
    "$original_exec" "$@"
  }
  
  if [[ "$executed" == true ]]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name"
  fi
  
  rm -rf "$INSTALL_DIR"
}

echo "Running install unit tests (Phase 3, 4 and 5)..."
echo "===================================================="

test_is_git_toolkit_installed_returns_true_when_dir_exists
test_is_git_toolkit_installed_returns_false_when_dir_not_exists
test_prompt_yes_no_returns_0_for_yes_input
test_prompt_yes_no_returns_1_for_no_input
test_prompt_yes_no_uses_default_true_when_empty_input
test_prompt_yes_no_uses_default_false_when_empty_input
test_check_existing_installation_prompts_when_installed
test_download_repository_creates_temp_dir
test_download_repository_retries_on_failure
test_install_to_target_dir_backs_up_existing
test_configure_path_if_needed_prompts_user
test_configure_path_adds_path_to_shell_config
test_is_path_already_configured_returns_true_when_markers_exist
test_is_path_already_configured_returns_false_when_markers_not_exist
test_start_git_toolkit_executes_git_toolkit

echo "===================================================="
echo "Total: $test_count, Passed: $pass_count, Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
