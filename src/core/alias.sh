#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/git.sh"
source "$SCRIPT_DIR/../utils/config.sh"

apply_preset_aliases() {
  local preset="${1:-full}"
  
  log_info "正在应用 Git aliases..."
  
  local aliases_to_apply=("${DEFAULT_ALIASES[@]}")
  
  for alias in "${aliases_to_apply[@]}"; do
    local name="${alias%%=*}"
    local command="${alias#*=}"
    git_set_config "alias.$name" "$command" "global"
    log_debug "设置 alias: $name = $command"
  done
  
  log_info "Aliases 应用完成"
}

add_alias() {
  local name="$1"
  local command="$2"
  
  if [[ -z "$name" || -z "$command" ]]; then
    log_error "Alias 名称和命令不能为空"
    return 1
  fi
  
  git_set_config "alias.$name" "$command" "global"
  log_info "Alias 已添加: $name = $command"
}

remove_alias() {
  local name="$1"
  
  git_unset_config "alias.$name" "global"
  log_info "Alias 已删除: $name"
}

list_aliases() {
  echo "Git Alias 列表:"
  echo "================================"
  
  local aliases=$(git config --global --get-regexp "^alias\." 2>/dev/null || true)
  
  if [[ -z "$aliases" ]]; then
    echo "未配置任何 alias"
  else
    while IFS= read -r line; do
      local name=$(echo "$line" | awk '{print $1}' | sed 's/alias\.//')
      local command=$(echo "$line" | cut -d' ' -f2-)
      echo "  $name = $command"
    done <<< "$aliases"
  fi
  
  echo "================================"
}
