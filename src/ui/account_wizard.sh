#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/prompt.sh"

prompt_ssh_key_option() {
  echo "请选择 SSH 密钥配置选项:"
  echo "1. 生成新的 SSH 密钥"
  echo "2. 选择已有的 SSH 密钥"
  echo "3. 暂不配置 SSH 密钥"
  
  local choice=$(prompt_choice "请选择:" "生成新的 SSH 密钥" "选择已有的 SSH 密钥" "暂不配置 SSH 密钥")
  
  case "$choice" in
    "生成新的 SSH 密钥")
      echo "generate"
      ;;
    "选择已有的 SSH 密钥")
      echo "select"
      ;;
    "暂不配置 SSH 密钥")
      echo "skip"
      ;;
  esac
}

prompt_domains() {
  local -a domains=()
  
  echo "请输入要关联的域名（每行一个，留空结束）:"
  
  while true; do
    local domain=$(prompt_text "域名" "")
    if [[ -z "$domain" ]]; then
      break
    fi
    domains+=("$domain")
  done
  
  if [[ ${#domains[@]} -gt 0 ]]; then
    local domains_str=""
    for domain in "${domains[@]}"; do
      domains_str="$domains_str \"$domain\""
    done
    echo "${domains_str:1}"
  fi
}

prompt_generate_ssh_key() {
  echo "生成新的 SSH 密钥"
  
  local default_name="id_rsa"
  local key_name=$(prompt_text "密钥名称" "$default_name")
  
  local default_comment="$USER@$(hostname)"
  local key_comment=$(prompt_text "密钥注释" "$default_comment")
  
  local key_path="$SSH_DIR/$key_name"
  
  echo "密钥路径: $key_path"
  
  echo "$key_path"
}

prompt_select_ssh_key() {
  echo "选择已有的 SSH 密钥"
  
  local -a available_keys=()
  while IFS= read -r key; do
    available_keys+=("$key")
  done < <(get_available_ssh_keys)
  
  if [[ ${#available_keys[@]} -eq 0 ]]; then
    echo "没有找到可用的 SSH 密钥"
    return 1
  fi
  
  local choice=$(prompt_choice "请选择 SSH 密钥:" "${available_keys[@]}")
  
  echo "$choice"
}

prompt_domain_key_mapping() {
  local domains_str="$1"
  local default_key_path="$2"
  
  local -a domain_key_mappings=()
  
  echo "配置域名-密钥映射（默认使用账号默认密钥，留空结束）:"
  
  local domains_array=()
  local temp_str="$domains_str"
  while [[ "$temp_str" =~ \"([^\"]+)\" ]]; do
    domains_array+=("${BASH_REMATCH[1]}")
    temp_str="${temp_str#*\"${BASH_REMATCH[1]}\"}"
  done
  
  for domain in "${domains_array[@]}"; do
    echo "域名: $domain"
    local use_default=$(prompt_yes_no "使用默认密钥？" "y")
    if ! $use_default; then
      local -a available_keys=()
      while IFS= read -r key; do
        available_keys+=("$key")
      done < <(get_available_ssh_keys)
      
      if [[ ${#available_keys[@]} -gt 0 ]]; then
        local key_choice=$(prompt_choice "请选择密钥:" "${available_keys[@]}")
        domain_key_mappings+=("$domain:$key_choice")
      fi
    fi
  done
  
  if [[ ${#domain_key_mappings[@]} -gt 0 ]]; then
    local mappings_str=""
    for mapping in "${domain_key_mappings[@]}"; do
      mappings_str="$mappings_str \"$mapping\""
    done
    echo "${mappings_str:1}"
  fi
}

run_account_add_wizard() {
  echo "=== 添加 Git 账号向导 ==="
  
  local account_name=$(prompt_text "账号名称" "")
  local user_name=$(prompt_text "Git 用户名" "")
  local user_email=$(prompt_text "Git 邮箱" "")
  
  local ssh_option=$(prompt_ssh_key_option)
  
  local ssh_key_path=""
  if [[ "$ssh_option" == "generate" ]]; then
    ssh_key_path=$(prompt_generate_ssh_key)
  elif [[ "$ssh_option" == "select" ]]; then
    ssh_key_path=$(prompt_select_ssh_key)
  fi
  
  local domains_str=$(prompt_domains)
  
  local domain_ssh_keys_str=""
  if [[ -n "$domains_str" && -n "$ssh_key_path" ]]; then
    domain_ssh_keys_str=$(prompt_domain_key_mapping "$domains_str" "$ssh_key_path")
  fi
  
  echo "=== 账号信息 ==="
  echo "账号名称: $account_name"
  echo "Git 用户名: $user_name"
  echo "Git 邮箱: $user_email"
  if [[ -n "$ssh_key_path" ]]; then
    echo "SSH 密钥: $ssh_key_path"
  fi
  if [[ -n "$domains_str" ]]; then
    echo "域名: $domains_str"
  fi
  if [[ -n "$domain_ssh_keys_str" ]]; then
    echo "域名-密钥映射: $domain_ssh_keys_str"
  fi
  
  echo "$account_name" "$user_name" "$user_email" "$ssh_key_path" "$domains_str" "$domain_ssh_keys_str"
}

prompt_simplified_ssh_key_option() {
  echo "请选择 SSH 密钥配置选项:"
  echo "1. 自动生成新的 SSH 密钥 (默认)"
  echo "2. 选择已有的 SSH 密钥"
  echo "3. 暂不配置 SSH 密钥"
  
  local choice=$(prompt_choice "请选择:" "自动生成新的 SSH 密钥 (默认)" "选择已有的 SSH 密钥" "暂不配置 SSH 密钥")
  
  case "$choice" in
    "选择已有的 SSH 密钥")
      echo "select"
      ;;
    "暂不配置 SSH 密钥")
      echo "skip"
      ;;
    *)
      echo "generate"
      ;;
  esac
}

prompt_simplified_generate_ssh_key() {
  local account_name="$1"
  local user_email="$2"
  
  local key_filename="id_ed25519_${account_name}"
  local key_comment="${account_name} ${user_email}"
  local key_path="$SSH_DIR/$key_filename"
  
  echo "$key_path" "$key_filename" "$key_comment"
}

run_simplified_account_add_wizard() {
  echo "=== 添加 Git 账号向导 (简化版) ==="
  
  local account_name=$(prompt_text "账号名称" "")
  local user_name=$(prompt_text "Git 用户名" "")
  local user_email=$(prompt_text "Git 邮箱" "")
  
  local ssh_option=$(prompt_simplified_ssh_key_option)
  
  local ssh_key_path=""
  local key_filename=""
  local key_comment=""
  
  if [[ "$ssh_option" == "generate" ]]; then
    read ssh_key_path key_filename key_comment < <(prompt_simplified_generate_ssh_key "$account_name" "$user_email")
  elif [[ "$ssh_option" == "select" ]]; then
    ssh_key_path=$(prompt_select_ssh_key)
  fi
  
  local domains_str=$(prompt_domains)
  
  local domain_ssh_keys_str=""
  if [[ -n "$domains_str" && -n "$ssh_key_path" ]]; then
    domain_ssh_keys_str=$(prompt_domain_key_mapping "$domains_str" "$ssh_key_path")
  fi
  
  echo "=== 账号信息 ==="
  echo "账号名称: $account_name"
  echo "Git 用户名: $user_name"
  echo "Git 邮箱: $user_email"
  if [[ -n "$ssh_key_path" ]]; then
    echo "SSH 密钥: $ssh_key_path"
  fi
  if [[ -n "$domains_str" ]]; then
    echo "域名: $domains_str"
  fi
  if [[ -n "$domain_ssh_keys_str" ]]; then
    echo "域名-密钥映射: $domain_ssh_keys_str"
  fi
  
  echo "$account_name" "$user_name" "$user_email" "$ssh_key_path" "$domains_str" "$domain_ssh_keys_str" "$key_filename" "$key_comment"
}
