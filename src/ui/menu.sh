#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/prompt.sh"

show_main_menu() {
  echo ""
  echo "================================"
  echo "  Git Toolkit v$GIT_TOOLKIT_VERSION"
  echo "================================"
  echo "1. 初始化 Git 环境"
  echo "2. SSH 密钥管理"
  echo "3. Git 账号管理"
  echo "4. Git Alias 管理"
  echo "5. 查看帮助"
  echo "0. 退出"
  echo "================================"
}

show_init_menu() {
  echo ""
  echo "=== 初始化 Git 环境 ==="
  
  local current_name=$(git config --global --get user.name 2>/dev/null || true)
  local current_email=$(git config --global --get user.email 2>/dev/null || true)
  
  local user_name
  echo -n "请输入用户名 [${current_name:-(未设置)}]: "
  read -r user_name || true
  if [[ -z "$user_name" ]]; then
    user_name="$current_name"
  fi
  
  local user_email
  echo -n "请输入邮箱地址 [${current_email:-(未设置)}]: "
  read -r user_email || true
  if [[ -z "$user_email" ]]; then
    user_email="$current_email"
  fi
  
  echo ""
  echo "即将应用以下配置："
  echo "  用户名: $user_name"
  echo "  邮箱:   $user_email"
  echo ""
  
  echo -n "确认继续吗？(Y/n): "
  read -r confirm || true
  if [[ "$confirm" =~ ^[Nn] ]]; then
    return 1
  else
    return 0
  fi
}

show_ssh_menu() {
  echo ""
  echo "=== SSH 密钥管理 ==="
  echo "1. 生成 SSH 密钥"
  echo "2. 列出 SSH 密钥"
  echo "3. 测试 SSH 连接"
  echo "0. 返回主菜单"
  echo "================================"
}

show_account_menu() {
  echo ""
  echo "=== Git 账号管理 ==="
  echo "1. 添加账号"
  echo "2. 列出账号"
  echo "3. 切换账号"
  echo "4. 删除账号"
  echo "5. 查看当前账号"
  echo "6. 安装/管理 cd 钩子"
  echo "7. 查看 SSH 配置"
  echo "0. 返回主菜单"
  echo "================================"
}

show_alias_menu() {
  echo ""
  echo "=== Git Alias 管理 ==="
  echo "1. 应用预设 aliases"
  echo "2. 添加 alias"
  echo "3. 删除 alias"
  echo "4. 列出 aliases"
  echo "0. 返回主菜单"
  echo "================================"
}
