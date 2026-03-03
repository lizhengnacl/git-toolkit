#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

git_set_config() {
  local key="$1"
  local value="$2"
  local scope="${3:-global}"

  git config "--$scope" "$key" "$value"
}

git_get_config() {
  local key="$1"
  local scope="${2:-global}"

  git config "--$scope" --get "$key" 2>/dev/null || true
}

git_unset_config() {
  local key="$1"
  local scope="${2:-global}"

  git config "--$scope" --unset "$key" 2>/dev/null || true
}

git_has_config() {
  local key="$1"
  local scope="${2:-global}"

  local value=$(git_get_config "$key" "$scope")
  [[ -n "$value" ]]
}

git_get_first_remote() {
  local repo_dir="${1:-.}"
  
  if [[ "$repo_dir" != "." ]]; then
    git -C "$repo_dir" remote 2>/dev/null | head -n 1 || true
  else
    git remote 2>/dev/null | head -n 1 || true
  fi
}

git_get_remote_url() {
  local remote_or_repo="$1"
  local repo_dir="${2:-.}"
  
  local remote_name
  if [[ "$#" -eq 1 ]]; then
    if [[ -d "$remote_or_repo" ]]; then
      repo_dir="$remote_or_repo"
      remote_name=$(git_get_first_remote "$repo_dir")
    else
      remote_name="$remote_or_repo"
      repo_dir="."
    fi
  else
    remote_name="$remote_or_repo"
  fi
  
  if [[ -z "$remote_name" ]]; then
    echo ""
    return 1
  fi
  
  if [[ "$repo_dir" != "." ]]; then
    git -C "$repo_dir" remote get-url "$remote_name" 2>/dev/null || true
  else
    git remote get-url "$remote_name" 2>/dev/null || true
  fi
}

git_is_repository() {
  local repo_dir="${1:-.}"
  
  if [[ "$repo_dir" != "." ]]; then
    git -C "$repo_dir" rev-parse --is-inside-work-tree &>/dev/null
  else
    git rev-parse --is-inside-work-tree &>/dev/null
  fi
}
