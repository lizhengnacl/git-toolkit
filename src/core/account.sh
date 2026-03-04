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
  local has_domains=false
  
  if [[ $# -gt 4 ]]; then
    shift 4
    has_domains=true
    save_account_config "$account_name" "$user_name" "$user_email" "$ssh_key_path" "$@"
  else
    save_account_config "$account_name" "$user_name" "$user_email" "$ssh_key_path"
  fi
  
  if ! validate_username "$user_name"; then
    log_error "无效的用户名"
    return 1
  fi
  
  if ! validate_email "$user_email"; then
    log_error "无效的邮箱地址"
    return 1
  fi
  
  if [[ -n "$ssh_key_path" && $has_domains == true ]]; then
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
      local cfg_domains_str=""
      local cfg_domain_ssh_keys_str=""
      
      while IFS= read -r line; do
        if [[ "$line" =~ ^GIT_USER_NAME=\"(.*)\"$ ]]; then
          cfg_name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^GIT_USER_EMAIL=\"(.*)\"$ ]]; then
          cfg_email="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^SSH_KEY_PATH=\"(.*)\"$ ]]; then
          cfg_ssh_key="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^DOMAINS=\((.*)\)$ ]]; then
          cfg_domains_str="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^DOMAIN_SSH_KEYS=\((.*)\)$ ]]; then
          cfg_domain_ssh_keys_str="${BASH_REMATCH[1]}"
        fi
      done < "$account_file"
      
      echo "- $account_name"
      echo "  用户名: $cfg_name"
      echo "  邮箱:   $cfg_email"
      if [[ -n "$cfg_ssh_key" ]]; then
        echo "  默认 SSH 密钥: $cfg_ssh_key"
      fi
      if [[ -n "$cfg_domains_str" ]]; then
        echo "  域名:    $cfg_domains_str"
      fi
      if [[ -n "$cfg_domain_ssh_keys_str" ]]; then
        echo "  域名-密钥映射:"
        local temp_str="$cfg_domain_ssh_keys_str"
        while [[ "$temp_str" =~ \"([^\"]+)\" ]]; do
          local mapping="${BASH_REMATCH[1]}"
          local domain=""
          local key_path=""
          parse_domain_key_entry "$mapping" domain key_path
          echo "    - $domain: $key_path"
          temp_str="${temp_str#*\"${BASH_REMATCH[1]}\"}"
        done
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

edit_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="$4"
  local domains_str="$5"
  local domain_ssh_keys_str="${6:-}"
  
  local config_file="$ACCOUNTS_DIR/$account_name.conf"
  
  if [[ ! -f "$config_file" ]]; then
    log_error "账号不存在: $account_name"
    return 1
  fi
  
  if ! validate_username "$user_name"; then
    log_error "无效的用户名"
    return 1
  fi
  
  if ! validate_email "$user_email"; then
    log_error "无效的邮箱地址"
    return 1
  fi
  
  remove_ssh_config_for_account "$account_name"
  save_account_config_with_mapping "$account_name" "$user_name" "$user_email" "$ssh_key_path" "$domains_str" "$domain_ssh_keys_str"
  
  if [[ -n "$ssh_key_path" ]]; then
    add_ssh_config_for_account "$account_name"
  fi
  
  log_info "账号编辑成功: $account_name"
}
