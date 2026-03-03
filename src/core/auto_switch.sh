#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/git.sh"

extract_domain_from_url() {
  local url="$1"
  
  if [[ "$url" =~ ^https?://([^/]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  
  if [[ "$url" =~ ^ssh://[^@]+@([^:/]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  
  if [[ "$url" =~ ^[^@]+@([^:]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  
  echo ""
  return 1
}

match_wildcard_domain() {
  local pattern="$1"
  local domain="$2"
  
  if [[ "$pattern" == *"*"* ]]; then
    if [[ "$pattern" =~ ^\*\.(.+)$ ]]; then
      local suffix="${BASH_REMATCH[1]}"
      [[ "$domain" == *"$suffix" ]]
    elif [[ "$pattern" =~ ^(.+)\.\*$ ]]; then
      local prefix="${BASH_REMATCH[1]}"
      [[ "$domain" == "$prefix".* ]]
    else
      return 1
    fi
  else
    [[ "$domain" == "$pattern" ]]
  fi
}

match_account_by_domain() {
  local target_domain="$1"
  
  if [[ ! -d "$ACCOUNTS_DIR" ]]; then
    echo ""
    return 1
  fi
  
  shopt -s nullglob
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      local account_name=$(basename "$account_file" .conf)
      
      local DOMAINS=()
      source "$account_file"
      
      if [[ ${#DOMAINS[@]} -gt 0 ]]; then
        for domain in "${DOMAINS[@]}"; do
          if [[ "$domain" == "$target_domain" ]]; then
            echo "$account_name"
            return 0
          fi
        done
      fi
    fi
  done
  
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      local account_name=$(basename "$account_file" .conf)
      
      local DOMAINS=()
      source "$account_file"
      
      if [[ ${#DOMAINS[@]} -gt 0 ]]; then
        for domain in "${DOMAINS[@]}"; do
          if [[ "$domain" == *"*"* ]] && match_wildcard_domain "$domain" "$target_domain"; then
            echo "$account_name"
            return 0
          fi
        done
      fi
    fi
  done
  
  echo ""
  return 1
}

auto_switch_account() {
  local repo_dir="${1:-.}"
  
  if ! git_is_repository "$repo_dir"; then
    log_info "Not a git repository, skipping"
    return 0
  fi
  
  local remote_url=$(git_get_remote_url "$repo_dir")
  if [[ -z "$remote_url" ]]; then
    log_info "No remote URL found, skipping"
    return 0
  fi
  
  local domain=$(extract_domain_from_url "$remote_url")
  if [[ -z "$domain" ]]; then
    log_info "Could not extract domain from URL: $remote_url"
    return 0
  fi
  
  local account=$(match_account_by_domain "$domain")
  if [[ -z "$account" ]]; then
    log_info "No account found for domain: $domain"
    return 0
  fi
  
  local config_file="$ACCOUNTS_DIR/$account.conf"
  if [[ ! -f "$config_file" ]]; then
    log_error "Account config not found: $account"
    return 1
  fi
  
  source "$config_file"
  
  cd "$repo_dir"
  git config --local user.name "$GIT_USER_NAME"
  git config --local user.email "$GIT_USER_EMAIL"
  
  log_info "Switched to account: $account"
  
  unset GIT_USER_NAME GIT_USER_EMAIL DOMAINS 2>/dev/null || true
}

is_cd_hook_installed() {
  local rc_file="$1"
  
  if [[ ! -f "$rc_file" ]]; then
    return 1
  fi
  
  grep -qF "$CD_HOOK_START_MARKER" "$rc_file"
}

get_shell_rc_file() {
  local shell_type=$(basename "$SHELL")
  
  if [[ "$shell_type" == "zsh" ]]; then
    echo "$HOME/.zshrc"
    return 0
  elif [[ "$shell_type" == "bash" ]]; then
    echo "$HOME/.bashrc"
    return 0
  else
    log_error "Unsupported shell: $shell_type"
    return 1
  fi
}

install_cd_hook() {
  local rc_file
  rc_file=$(get_shell_rc_file) || return 1
  
  if [[ ! -f "$rc_file" ]]; then
    touch "$rc_file"
  fi
  
  if is_cd_hook_installed "$rc_file"; then
    log_info "cd hook already installed"
    return 0
  fi
  
  cat >> "$rc_file" <<EOF

$CD_HOOK_START_MARKER
cd() {
  builtin cd "\$@"
  if command -v git-toolkit >/dev/null 2>&1; then
    git-toolkit account auto-switch 2>/dev/null || true
  fi
}
$CD_HOOK_END_MARKER
EOF
  
  log_info "cd hook installed to $rc_file"
  log_info "Please restart your shell or run: source $rc_file"
}

uninstall_cd_hook() {
  local rc_file
  rc_file=$(get_shell_rc_file) || return 1
  
  if [[ ! -f "$rc_file" ]]; then
    log_info "Shell config file not found"
    return 0
  fi
  
  if ! is_cd_hook_installed "$rc_file"; then
    log_info "cd hook not installed"
    return 0
  fi
  
  local temp_file=$(mktemp)
  local in_hook=false
  
  while IFS= read -r line; do
    if [[ "$line" == "$CD_HOOK_START_MARKER" ]]; then
      in_hook=true
    elif [[ "$line" == "$CD_HOOK_END_MARKER" ]]; then
      in_hook=false
    elif [[ "$in_hook" == false ]]; then
      echo "$line"
    fi
  done < "$rc_file" > "$temp_file"
  
  mv "$temp_file" "$rc_file"
  
  log_info "cd hook uninstalled from $rc_file"
}
