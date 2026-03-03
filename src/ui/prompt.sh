#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

prompt_text() {
  local prompt="$1"
  local default="${2:-}"
  
  if [[ -n "$default" ]]; then
    echo -n "$prompt [$default]: "
  else
    echo -n "$prompt: "
  fi
  
  read -r response || true
  
  if [[ -z "$response" && -n "$default" ]]; then
    echo "$default"
  else
    echo "$response"
  fi
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  
  if [[ ! -t 0 ]]; then
    if [[ "$default" == "y" ]]; then
      return 0
    else
      return 1
    fi
  fi
  
  while true; do
    local options="[y/n]"
    if [[ "$default" == "y" ]]; then
      options="[Y/n]"
    elif [[ "$default" == "n" ]]; then
      options="[y/N]"
    fi
    
    echo -n "$prompt $options: "
    read -r response || true
    
    if [[ -z "$response" ]]; then
      response="$default"
    fi
    
    case "$response" in
      [Yy]*)
        return 0
        ;;
      [Nn]*)
        return 1
        ;;
      *)
        echo "请输入 y 或 n"
        ;;
    esac
  done
}

prompt_choice() {
  local prompt="$1"
  shift
  local -a options=("$@")
  
  if [[ ! -t 0 ]]; then
    echo "${options[0]}"
    return 0
  fi
  
  echo "$prompt"
  for i in "${!options[@]}"; do
    echo "$((i + 1)). ${options[$i]}"
  done
  
  while true; do
    echo -n "请选择: "
    read -r choice || true
    
    if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
      echo "${options[$((choice - 1))]}"
      return 0
    else
      echo "无效的选择，请输入 1-${#options[@]} 之间的数字"
    fi
  done
}
