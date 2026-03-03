#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/logger.sh"

load_account_config() {
  local account_name="$1"
  local config_file="$ACCOUNTS_DIR/$account_name.conf"

  if [[ ! -f "$config_file" ]]; then
    log_error "Account config not found: $account_name"
    return 1
  fi

  source "$config_file"
  log_debug "Loaded account config: $account_name"
}

save_account_config() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="${4:-}"
  local -a domains=("${@:5}")

  mkdir -p "$ACCOUNTS_DIR"

  local config_file="$ACCOUNTS_DIR/$account_name.conf"

  cat > "$config_file" <<EOF
ACCOUNT_NAME="$account_name"
GIT_USER_NAME="$user_name"
GIT_USER_EMAIL="$user_email"
EOF

  if [[ -n "$ssh_key_path" ]]; then
    echo "SSH_KEY_PATH=\"$ssh_key_path\"" >> "$config_file"
  fi

  if [[ ${#domains[@]} -gt 0 ]]; then
    printf 'DOMAINS=(' >> "$config_file"
    local first=true
    for domain in "${domains[@]}"; do
      if $first; then
        first=false
      else
        printf ' ' >> "$config_file"
      fi
      printf '"%s"' "$domain" >> "$config_file"
    done
    printf ')\n' >> "$config_file"
  fi

  log_info "Saved account config: $account_name"
}

load_alias_config() {
  local alias_file="$GIT_TOOLKIT_DIR/aliases"

  if [[ -f "$alias_file" ]]; then
    cat "$alias_file"
  else
    echo "[alias]"
  fi
}

save_alias_config() {
  local alias_content="$1"

  mkdir -p "$GIT_TOOLKIT_DIR"
  echo "$alias_content" > "$GIT_TOOLKIT_DIR/aliases"
  log_info "Saved alias config"
}
