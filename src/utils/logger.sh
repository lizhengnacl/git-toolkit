#!/usr/bin/env bash

GIT_TOOLKIT_LOG_LEVEL="${GIT_TOOLKIT_LOG_LEVEL:-INFO}"

LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR")

get_log_level_index() {
  local level="$1"
  for i in "${!LOG_LEVELS[@]}"; do
    if [[ "${LOG_LEVELS[$i]}" == "$level" ]]; then
      echo "$i"
      return
    fi
  done
  echo "1"
}

should_log() {
  local message_level="$1"
  local current_level_index=$(get_log_level_index "$GIT_TOOLKIT_LOG_LEVEL")
  local message_level_index=$(get_log_level_index "$message_level")
  [[ $message_level_index -ge $current_level_index ]]
}

log_debug() {
  local message="$1"
  if should_log "DEBUG"; then
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
  fi
}

log_info() {
  local message="$1"
  if should_log "INFO"; then
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
  fi
}

log_warn() {
  local message="$1"
  if should_log "WARN"; then
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
  fi
}

log_error() {
  local message="$1"
  if should_log "ERROR"; then
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
  fi
}
