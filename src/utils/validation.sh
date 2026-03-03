#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

validate_email() {
  local email="$1"
  local email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
  
  [[ "$email" =~ $email_regex ]]
}

validate_username() {
  local username="$1"
  [[ -n "$username" && ${#username} -ge 1 ]]
}

validate_domain() {
  local domain="$1"
  
  if [[ "$domain" == *"*"* ]]; then
    [[ "$domain" =~ ^\*\.[a-zA-Z0-9.-]+$ ]] || [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.\*$ ]]
  else
    local domain_regex="^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    [[ -n "$domain" && "$domain" =~ $domain_regex ]]
  fi
}

validate_path() {
  local path="$1"
  
  if [[ "$path" =~ \.\. ]]; then
    return 1
  fi
  
  if [[ "$path" =~ ^/ ]]; then
    return 1
  fi
  
  return 0
}
