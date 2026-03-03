#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/git.sh"
source "$SCRIPT_DIR/../utils/backup.sh"
source "$SCRIPT_DIR/../utils/validation.sh"

configure_git_settings() {
  local user_name="$1"
  local user_email="$2"
  
  log_info "配置 Git 用户信息..."
  git_set_config "user.name" "$user_name" "global"
  git_set_config "user.email" "$user_email" "global"
  log_info "Git 用户信息配置完成"
}

apply_default_aliases() {
  log_info "应用默认 Git aliases..."
  for alias in "${DEFAULT_ALIASES[@]}"; do
    local name="${alias%%=*}"
    local command="${alias#*=}"
    git_set_config "alias.$name" "$command" "global"
    log_debug "设置 alias: $name = $command"
  done
  log_info "默认 aliases 应用完成"
}

init_git_environment() {
  local user_name="$1"
  local user_email="$2"
  
  log_info "开始初始化 Git 环境..."
  
  mkdir -p "$GIT_TOOLKIT_DIR"
  mkdir -p "$BACKUP_DIR"
  mkdir -p "$ACCOUNTS_DIR"
  
  local gitconfig_path="$HOME/.gitconfig"
  if [[ -f "$gitconfig_path" ]]; then
    log_info "备份现有 Git 配置..."
    create_backup "$gitconfig_path"
  fi
  
  configure_git_settings "$user_name" "$user_email"
  apply_default_aliases
  
  log_info "Git 环境初始化完成"
}
