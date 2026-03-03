#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../constants.sh"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/backup.sh"

add_ssh_config() {
  local domain="$1"
  local ssh_key_path="$2"
  
  if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
    touch "$SSH_CONFIG_FILE"
  else
    create_backup "$SSH_CONFIG_FILE" 2>/dev/null || true
  fi
  
  remove_ssh_config "$domain" 2>/dev/null || true
  
  local temp_file=$(mktemp)
  
  if ! grep -qF "$SSH_CONFIG_START_MARKER" "$SSH_CONFIG_FILE"; then
    cat "$SSH_CONFIG_FILE" > "$temp_file"
    echo "" >> "$temp_file"
    echo "$SSH_CONFIG_START_MARKER" >> "$temp_file"
    echo "Host $domain" >> "$temp_file"
    echo "  IdentityFile $ssh_key_path" >> "$temp_file"
    echo "  IdentitiesOnly yes" >> "$temp_file"
    echo "$SSH_CONFIG_END_MARKER" >> "$temp_file"
  else
    local in_block=false
    local added=false
    while IFS= read -r line; do
      if [[ "$line" == "$SSH_CONFIG_START_MARKER" ]]; then
        in_block=true
        echo "$line" >> "$temp_file"
        if [[ "$added" == false ]]; then
          echo "Host $domain" >> "$temp_file"
          echo "  IdentityFile $ssh_key_path" >> "$temp_file"
          echo "  IdentitiesOnly yes" >> "$temp_file"
          added=true
        fi
      elif [[ "$line" == "$SSH_CONFIG_END_MARKER" ]]; then
        in_block=false
        echo "$line" >> "$temp_file"
      elif [[ "$in_block" == false ]]; then
        echo "$line" >> "$temp_file"
      else
        echo "$line" >> "$temp_file"
      fi
    done < "$SSH_CONFIG_FILE"
  fi
  
  mv "$temp_file" "$SSH_CONFIG_FILE"
  log_info "Added SSH config for domain: $domain"
}

remove_ssh_config() {
  local domain="$1"
  
  if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
    return 0
  fi
  
  create_backup "$SSH_CONFIG_FILE" 2>/dev/null || true
  
  local temp_file=$(mktemp)
  local in_block=false
  local skip_host=false
  
  while IFS= read -r line; do
    if [[ "$line" == "$SSH_CONFIG_START_MARKER" ]]; then
      in_block=true
      echo "$line" >> "$temp_file"
    elif [[ "$line" == "$SSH_CONFIG_END_MARKER" ]]; then
      in_block=false
      echo "$line" >> "$temp_file"
    elif [[ "$in_block" == true && "$line" =~ ^Host[[:space:]]+"$domain"$ ]]; then
      skip_host=true
    elif [[ "$in_block" == true && "$skip_host" == true && "$line" =~ ^Host[[:space:]]+ ]]; then
      skip_host=false
      echo "$line" >> "$temp_file"
    elif [[ "$skip_host" == false ]]; then
      echo "$line" >> "$temp_file"
    fi
  done < "$SSH_CONFIG_FILE"
  
  mv "$temp_file" "$SSH_CONFIG_FILE"
  log_info "Removed SSH config for domain: $domain"
}

add_ssh_config_for_account() {
  local account_name="$1"
  local config_file="$ACCOUNTS_DIR/$account_name.conf"
  
  if [[ ! -f "$config_file" ]]; then
    log_error "Account not found: $account_name"
    return 1
  fi
  
  source "$config_file"
  
  local has_ssh_key=false
  local has_domains=false
  
  if [[ -n "${SSH_KEY_PATH:-}" ]]; then
    has_ssh_key=true
  fi
  
  if [[ -n "${DOMAINS:-}" && ${#DOMAINS[@]} -gt 0 ]]; then
    has_domains=true
  fi
  
  if [[ "$has_ssh_key" == true && "$has_domains" == true ]]; then
    for domain in "${DOMAINS[@]}"; do
      add_ssh_config "$domain" "$SSH_KEY_PATH"
    done
  fi
  
  unset DOMAINS SSH_KEY_PATH 2>/dev/null || true
}

remove_ssh_config_for_account() {
  local account_name="$1"
  local config_file="$ACCOUNTS_DIR/$account_name.conf"
  
  if [[ ! -f "$config_file" ]]; then
    log_error "Account not found: $account_name"
    return 1
  fi
  
  source "$config_file"
  
  local has_domains=false
  if [[ -n "${DOMAINS:-}" && ${#DOMAINS[@]} -gt 0 ]]; then
    has_domains=true
  fi
  
  if [[ "$has_domains" == true ]]; then
    for domain in "${DOMAINS[@]}"; do
      remove_ssh_config "$domain"
    done
  fi
  
  unset DOMAINS 2>/dev/null || true
}

list_managed_ssh_config() {
  if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
    echo "No SSH config file found"
    return 0
  fi
  
  local in_block=false
  echo "Managed SSH Config:"
  echo "================================"
  
  while IFS= read -r line; do
    if [[ "$line" == "$SSH_CONFIG_START_MARKER" ]]; then
      in_block=true
    elif [[ "$line" == "$SSH_CONFIG_END_MARKER" ]]; then
      in_block=false
    elif [[ "$in_block" == true ]]; then
      echo "$line"
    fi
  done < "$SSH_CONFIG_FILE"
  
  echo "================================"
}

rebuild_all_ssh_config() {
  if [[ -f "$SSH_CONFIG_FILE" ]]; then
    create_backup "$SSH_CONFIG_FILE" 2>/dev/null || true
    
    local temp_file=$(mktemp)
    local in_block=false
    
    while IFS= read -r line; do
      if [[ "$line" == "$SSH_CONFIG_START_MARKER" ]]; then
        in_block=true
      elif [[ "$line" == "$SSH_CONFIG_END_MARKER" ]]; then
        in_block=false
      elif [[ "$in_block" == false ]]; then
        echo "$line" >> "$temp_file"
      fi
    done < "$SSH_CONFIG_FILE"
    
    echo "" >> "$temp_file"
    echo "$SSH_CONFIG_START_MARKER" >> "$temp_file"
    echo "$SSH_CONFIG_END_MARKER" >> "$temp_file"
    
    mv "$temp_file" "$SSH_CONFIG_FILE"
  else
    touch "$SSH_CONFIG_FILE"
    echo "$SSH_CONFIG_START_MARKER" >> "$SSH_CONFIG_FILE"
    echo "$SSH_CONFIG_END_MARKER" >> "$SSH_CONFIG_FILE"
  fi
  
  if [[ ! -d "$ACCOUNTS_DIR" ]]; then
    log_info "No accounts found, SSH config rebuilt"
    return 0
  fi
  
  for account_file in "$ACCOUNTS_DIR"/*.conf; do
    if [[ -f "$account_file" ]]; then
      local account_name=$(basename "$account_file" .conf)
      add_ssh_config_for_account "$account_name"
    fi
  done
  
  log_info "SSH config rebuilt successfully"
}
