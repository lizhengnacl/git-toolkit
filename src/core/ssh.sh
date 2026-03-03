#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/validation.sh"

generate_ssh_key() {
  local key_type="${1:-ed25519}"
  local key_filename="${2:-id_ed25519}"
  local key_comment="${3:-}"
  
  local ssh_dir="$HOME/.ssh"
  mkdir -p "$ssh_dir"
  
  local key_path="$ssh_dir/$key_filename"
  local pub_key_path="$key_path.pub"
  
  if [[ -f "$key_path" ]]; then
    log_warn "密钥文件已存在: $key_path"
    return 1
  fi
  
  log_info "正在生成 SSH 密钥..."
  log_info "类型: $key_type"
  log_info "文件: $key_path"
  
  local ssh_keygen_args=("-t" "$key_type" "-f" "$key_path" "-N" "")
  
  if [[ -n "$key_comment" ]]; then
    ssh_keygen_args+=("-C" "$key_comment")
  fi
  
  ssh-keygen "${ssh_keygen_args[@]}" >/dev/null 2>&1
  
  log_info "SSH 密钥生成成功！"
  echo ""
  echo "公钥内容 ($pub_key_path):"
  echo "================================"
  cat "$pub_key_path"
  echo "================================"
  echo ""
  echo "请将上述公钥添加到您的 Git 平台（GitHub/GitLab/Gitee 等）"
  echo ""
}

list_ssh_keys() {
  local ssh_dir="$HOME/.ssh"
  
  if [[ ! -d "$ssh_dir" ]]; then
    log_warn "SSH 目录不存在: $ssh_dir"
    return 0
  fi
  
  echo "SSH 密钥列表:"
  echo "================================"
  
  local has_keys=false
  
  for key_file in "$ssh_dir"/*; do
    if [[ -f "$key_file" && ! "$key_file" =~ \.pub$ ]]; then
      local is_ssh_key=false
      
      if head -1 "$key_file" 2>/dev/null | grep -E "(BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY|PuTTY-User-Key-File)" >/dev/null; then
        is_ssh_key=true
      fi
      
      if $is_ssh_key; then
        local pub_key_file="$key_file.pub"
        local key_name=$(basename "$key_file")
        local key_comment=""
        
        if [[ -f "$pub_key_file" ]]; then
          key_comment=$(awk '{print $NF}' "$pub_key_file" 2>/dev/null || true)
        fi
        
        echo "- $key_name"
        if [[ -n "$key_comment" ]]; then
          echo "  Comment: $key_comment"
        fi
        echo ""
        has_keys=true
      fi
    fi
  done
  
  if ! $has_keys; then
    echo "未找到 SSH 密钥"
  fi
  
  echo "================================"
}

test_ssh_connection() {
  local domain="${1:-github.com}"
  local temp_file=$(mktemp)
  
  log_info "正在测试 SSH 连接到 $domain..."
  echo ""
  echo "执行命令: ssh -o ConnectTimeout=5 -o BatchMode=yes -T git@$domain"
  echo ""
  
  ssh -o ConnectTimeout=5 -o BatchMode=yes -T "git@$domain" 2>&1 | tee "$temp_file"
  
  local ssh_exit_code=${PIPESTATUS[0]}
  
  if grep -q -E "successfully authenticated|Hi|Welcome to" "$temp_file"; then
    echo ""
    log_info "SSH 连接成功！"
    rm -f "$temp_file"
    return 0
  else
    echo ""
    log_error "SSH 连接失败，请检查您的密钥配置"
    echo ""
    echo "常见问题排查:"
    echo "1. 确认公钥已添加到 Git 平台"
    echo "2. 检查 ~/.ssh/config 配置"
    echo "3. 确认密钥文件权限正确 (600)"
    echo "4. 尝试: ssh -v git@$domain 查看详细日志"
    rm -f "$temp_file"
    return 1
  fi
}
