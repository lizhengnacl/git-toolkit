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
  local -a domains=()
  
  if [[ $# -gt 4 ]]; then
    shift 4
    domains=("$@")
  fi

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

save_account_config_with_mapping() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="${4:-}"
  local domains_str="$5"
  local domain_ssh_keys_str="$6"

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

  if [[ -n "$domains_str" ]]; then
    echo "DOMAINS=($domains_str)" >> "$config_file"
  fi

  if [[ -n "$domain_ssh_keys_str" ]]; then
    echo "DOMAIN_SSH_KEYS=($domain_ssh_keys_str)" >> "$config_file"
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

load_all_accounts() {
  local result_var="$1"
  
  if [[ ! -d "$ACCOUNTS_DIR" ]]; then
    eval "$result_var=()"
    return 0
  fi
  
  local -a accounts=()
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      local account_name=$(basename "$account_file" .conf)
      accounts+=("$account_name")
    fi
  done
  
  if [[ ${#accounts[@]} -gt 0 ]]; then
    eval "$result_var=(\"\${accounts[@]}\")"
  else
    eval "$result_var=()"
  fi
}

build_domain_account_map() {
  local result_var="$1"
  
  if [[ ! -d "$ACCOUNTS_DIR" ]]; then
    eval "$result_var=()"
    return 0
  fi
  
  declare -A temp_map
  
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      local account_name=$(basename "$account_file" .conf)
      source "$account_file"
      
      if [[ -n "${DOMAINS:-}" && ${#DOMAINS[@]} -gt 0 ]]; then
        for domain in "${DOMAINS[@]}"; do
          temp_map["$domain"]="$account_name"
        done
      fi
      
      unset DOMAINS 2>/dev/null || true
    fi
  done
  
  eval "$result_var=()"
  for key in "${!temp_map[@]}"; do
    eval "$result_var[\"$key\"]=\"${temp_map[$key]}\""
  done
}

parse_domain_key_entry() {
  local entry="$1"
  local domain_var="$2"
  local key_path_var="$3"
  
  local OLD_IFS="$IFS"
  IFS=':'
  local parts=($entry)
  IFS="$OLD_IFS"
  
  if [[ ${#parts[@]} -lt 2 ]]; then
    return 1
  fi
  
  local domain_part="${parts[0]}"
  local key_path_part=""
  local i=1
  while [[ $i -lt ${#parts[@]} ]]; do
    if [[ -n "$key_path_part" ]]; then
      key_path_part="$key_path_part:${parts[$i]}"
    else
      key_path_part="${parts[$i]}"
    fi
    i=$((i + 1))
  done
  
  domain_part=$(echo "$domain_part" | awk '{$1=$1};1')
  key_path_part=$(echo "$key_path_part" | awk '{$1=$1};1')
  
  if [[ -z "$domain_part" || -z "$key_path_part" ]]; then
    return 1
  fi
  
  eval "$domain_var=\"$domain_part\""
  eval "$key_path_var=\"$key_path_part\""
  
  return 0
}

build_domain_key_entry() {
  local domain="$1"
  local key_path="$2"
  
  echo "$domain:$key_path"
}

extract_domains_from_config() {
  local config_file="$1"
  local result_var="$2"
  
  eval "$result_var=()"
  
  if [[ ! -f "$config_file" ]]; then
    return 0
  fi
  
  local temp_file=$(mktemp)
  source "$config_file" 2>/dev/null || true
  
  if [[ -n "${DOMAINS:-}" && ${#DOMAINS[@]} -gt 0 ]]; then
    eval "$result_var=(\"\${DOMAINS[@]}\")"
  fi
  
  rm -f "$temp_file"
  unset DOMAINS 2>/dev/null || true
}

get_key_for_domain() {
  local domain="$1"
  local default_key="$2"
  local result_var="$3"
  shift 3
  
  while [[ $# -gt 0 ]]; do
    local entry="$1"
    local entry_domain=""
    local entry_key=""
    
    if parse_domain_key_entry "$entry" entry_domain entry_key; then
      if [[ "$entry_domain" == "$domain" ]]; then
        eval "$result_var=\"$entry_key\""
        return 0
      fi
    fi
    shift
  done
  
  eval "$result_var=\"$default_key\""
  return 0
}
