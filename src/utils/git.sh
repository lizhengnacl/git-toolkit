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
