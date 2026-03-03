#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/logger.sh"

create_backup() {
  local source_path="$1"
  local backup_dir="${2:-$BACKUP_DIR}"

  if [[ ! -f "$source_path" ]]; then
    log_error "Source file not found: $source_path"
    return 1
  fi

  mkdir -p "$backup_dir"

  local filename=$(basename "$source_path")
  local timestamp=$(date '+%Y%m%d-%H%M%S')
  local backup_path="$backup_dir/${filename}.${timestamp}.bak"

  cp "$source_path" "$backup_path"
  log_info "Created backup: $backup_path"
  echo "$backup_path"
}

list_backups() {
  local pattern="${1:-*}"

  if [[ ! -d "$BACKUP_DIR" ]]; then
    return 0
  fi

  find "$BACKUP_DIR" -name "$pattern" -type f | sort -r
}

restore_backup() {
  local backup_path="$1"
  local target_path="$2"

  if [[ ! -f "$backup_path" ]]; then
    log_error "Backup file not found: $backup_path"
    return 1
  fi

  if [[ -f "$target_path" ]]; then
    create_backup "$target_path"
  fi

  cp "$backup_path" "$target_path"
  log_info "Restored backup: $backup_path -> $target_path"
}
