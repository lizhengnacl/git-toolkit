#!/usr/bin/env bash

GIT_TOOLKIT_VERSION="0.1.0"

GIT_TOOLKIT_DIR="${GIT_TOOLKIT_DIR:-${HOME}/.git-toolkit}"
ACCOUNTS_DIR="${ACCOUNTS_DIR:-${GIT_TOOLKIT_DIR}/accounts}"
BACKUP_DIR="${BACKUP_DIR:-${GIT_TOOLKIT_DIR}/backup}"

SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-${HOME}/.ssh/config}"
SSH_CONFIG_START_MARKER="# === git-toolkit managed start ==="
SSH_CONFIG_END_MARKER="# === git-toolkit managed end ==="

# 专家模式
EXPERT_MODE_ENV_VAR="GIT_TOOLKIT_EXPERT_MODE"

# 配置迁移
MIGRATION_VERSION="5"
MIGRATION_MARKER_FILE="${GIT_TOOLKIT_DIR}/.migration_v${MIGRATION_VERSION}"

CD_HOOK_START_MARKER="# === git-toolkit auto-switch start ==="
CD_HOOK_END_MARKER="# === git-toolkit auto-switch end ==="

DEFAULT_ALIASES=(
  "st=status"
  "co=checkout"
  "br=branch"
  "ci=commit"
  "cm=commit -m"
  "unstage=reset HEAD --"
  "last=log -1 HEAD"
)

EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_INVALID_ARG=2

COLOR_RESET="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
