#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/git.sh"
source "$SCRIPT_DIR/../utils/config.sh"
source "$SCRIPT_DIR/../utils/validation.sh"
source "$SCRIPT_DIR/../utils/ssh_config.sh"

add_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="${4:-}"
  local -a domains=()
  
  if [[ $# -gt 4 ]]; then
    shift 4
    domains=("$@")
  fi
  
  if ! validate_username "$user_name"; then
    log_error "无效的用户名"
    return 1
  fi
  
  if ! validate_email "$user_email"; then
    log_error "无效的邮箱地址"
    return 1
  fi
  
  save_account_config "$account_name" "$user_name" "$user_email" "$ssh_key_path" "${domains[@]}"
  
  if [[ -n "$ssh_key_path" && ${#domains[@]} -gt 0 ]]; then
    add_ssh_config_for_account "$account_name"
  fi
  
  log_info "账号添加成功: $account_name"
}

list_accounts() {
  echo "Git 账号列表:"
  echo "================================"
  
  if [[ ! -d "$ACCOUNTS_DIR" ]]; then
    echo "未配置任何账号"
    echo "================================"
    return 0
  fi
  
  local has_accounts=false
  
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      has_accounts=true
      local account_name=$(basename "$account_file" .conf)
      
      local cfg_name=""
      local cfg_email=""
      local cfg_ssh_key=""
      local -a cfg_domains=()
      
      while IFS= read -r line; do
        if [[ "$line" =~ ^GIT_USER_NAME=\"(.*)\"$ ]]; then
          cfg_name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^GIT_USER_EMAIL=\"(.*)\"$ ]]; then
          cfg_email="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^SSH_KEY_PATH=\"(.*)\"$ ]]; then
          cfg_ssh_key="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^DOMAINS=\((.*)\)$ ]]; then
          local domains_str="${BASH_REMATCH[1]}"
          while [[ "$domains_str" =~ \"([^\"]+)\" ]]; do
            cfg_domains+=("${BASH_REMATCH[1]}")
            domains_str="${domains_str#*\"${BASH_REMATCH[1]}\"}"
          done
        fi
      done < "$account_file"
      
      echo "- $account_name"
      echo "  用户名: $cfg_name"
      echo "  邮箱:   $cfg_email"
      if [[ -n "$cfg_ssh_key" ]]; then
        echo "  SSH 密钥: $cfg_ssh_key"
      fi
      if [[ ${#cfg_domains[@]} -gt 0 ]]; then
        echo "  域名:    ${cfg_domains[*]}"
      fi
      echo ""
    fi
  done
  
  if ! $has_accounts; then
    echo "未配置任何账号"
  fi
  
  echo "================================"
}

switch_account() {
  local account_name="$1"
  local config_file="$ACCOUNTS_DIR/$account_name.conf"
  
  if [[ ! -f "$config_file" ]]; then
    log_error "账号不存在: $account_name"
    return 1
  fi
  
  local cfg_name=""
  local cfg_email=""
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^GIT_USER_NAME=\"(.*)\"$ ]]; then
      cfg_name="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^GIT_USER_EMAIL=\"(.*)\"$ ]]; then
      cfg_email="${BASH_REMATCH[1]}"
    fi
  done < "$config_file"
  
  log_info "正在切换到账号: $account_name"
  
  git_set_config "user.name" "$cfg_name" "global"
  git_set_config "user.email" "$cfg_email" "global"
  
  log_info "账号切换成功"
}

delete_account() {
  local account_name="$1"
  local config_file="$ACCOUNTS_DIR/$account_name.conf"
  
  if [[ ! -f "$config_file" ]]; then
    log_error "账号不存在: $account_name"
    return 1
  fi
  
  remove_ssh_config_for_account "$account_name"
  rm "$config_file"
  log_info "账号已删除: $account_name"
}

get_current_account() {
  local name=$(git_get_config "user.name" "global")
  local email=$(git_get_config "user.email" "global")
  
  echo "当前 Git 配置:"
  echo "================================"
  echo "用户名: $name"
  echo "邮箱:   $email"
  echo "================================"
}
