#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# 强制使用 C 语言环境以确保一致的行为
export LC_ALL=C

# 仓库配置
GITHUB_REPO_OWNER="username"
GITHUB_REPO_NAME="git-toolkit"
GITHUB_BRANCH="main"
GIT_REPO_URL="https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git"

# 安装配置
INSTALL_DIR="${HOME}/.git-toolkit"
MAX_RETRY_COUNT=3
RETRY_INTERVAL=2

# Shell 配置标识块
PATH_CONFIG_START_MARKER="# === git-toolkit PATH start ==="
PATH_CONFIG_END_MARKER="# === git-toolkit PATH end ==="

# 颜色输出（ANSI 转义码）
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

# 临时目录
TEMP_DIR=""

# 检测结果
OS_TYPE=""
USER_SHELL=""
SHELL_CONFIG_FILE=""
HAS_CURL=false
HAS_WGET=false
HAS_GIT=false

cleanup() {
  if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

print_welcome_banner() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                    Git Toolkit 安装向导                         ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
}

print_success() {
  local message="$1"
  echo -e "${COLOR_GREEN}✅ ${message}${COLOR_RESET}"
}

print_warning() {
  local message="$1"
  echo -e "${COLOR_YELLOW}⚠️  ${message}${COLOR_RESET}"
}

print_error() {
  local message="$1"
  echo -e "${COLOR_RED}❌ ${message}${COLOR_RESET}" >&2
}

print_info() {
  local message="$1"
  local indent="${2:-0}"
  local prefix=""
  for ((i=0; i<indent; i++)); do
    prefix+="  "
  done
  echo -e "${prefix}${message}"
}

detect_os_type() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_TYPE="macos"
  else
    OS_TYPE="linux"
  fi
  print_success "检测系统: ${OS_TYPE}"
}

detect_user_shell() {
  local shell_basename
  shell_basename=$(basename "${SHELL:-}")
  if [[ "$shell_basename" == "zsh" ]]; then
    USER_SHELL="zsh"
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
  elif [[ "$shell_basename" == "bash" ]]; then
    USER_SHELL="bash"
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
  else
    USER_SHELL="bash"
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
    print_warning "无法识别 Shell: ${shell_basename}，默认使用 bash"
  fi
}

check_dependencies() {
  local missing_deps=()

  if command -v git &>/dev/null; then
    HAS_GIT=true
  else
    HAS_GIT=false
    missing_deps+=("git")
  fi

  if command -v curl &>/dev/null; then
    HAS_CURL=true
  else
    HAS_CURL=false
  fi

  if command -v wget &>/dev/null; then
    HAS_WGET=true
  else
    HAS_WGET=false
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    print_error "缺少必要依赖: ${missing_deps[*]}"
    print_install_hints "${missing_deps[@]}"
    exit 1
  fi

  local tool_list="git"
  [[ $HAS_CURL == true ]] && tool_list="$tool_list, curl"
  [[ $HAS_WGET == true ]] && tool_list="$tool_list, wget"
  print_success "检查依赖: ${tool_list} 均已安装"
}

print_install_hints() {
  local -a deps=("$@")
  echo ""
  echo "安装提示:"
  for dep in "${deps[@]}"; do
    case "$dep" in
      git)
        echo "  macOS:   xcode-select --install"
        echo "  Ubuntu:  sudo apt-get install git"
        echo "  CentOS:  sudo yum install git"
        ;;
    esac
  done
  echo ""
}

is_git_toolkit_installed() {
  [[ -d "$INSTALL_DIR" ]]
}

check_existing_installation() {
  if is_git_toolkit_installed; then
    print_warning "检测到已安装 git-toolkit"
    if ! prompt_yes_no "是否覆盖安装最新版本?" false; then
      print_info "用户取消安装，退出"
      exit 0
    fi
  fi
}

prompt_yes_no() {
  local question="$1"
  local default="${2:-true}"
  local prompt
  local default_answer

  if [[ "$default" == true ]]; then
    prompt="[Y/n]"
    default_answer="y"
  else
    prompt="[y/N]"
    default_answer="n"
  fi

  while true; do
    read -r -p "   ${question} ${prompt} " answer
    answer=${answer:-$default_answer}
    case "$answer" in
      [Yy]*)
        return 0
        ;;
      [Nn]*)
        return 1
        ;;
      *)
        print_warning "请输入 y 或 n"
        ;;
    esac
  done
}

download_repository() {
  echo ""
  print_info "📥 下载最新代码..."

  TEMP_DIR=$(mktemp -d -t git-toolkit-XXXXXX)

  local attempt=1
  while [[ $attempt -le $MAX_RETRY_COUNT ]]; do
    if git clone --depth 1 --branch "$GITHUB_BRANCH" "$GIT_REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
      print_info "   尝试 ${attempt}/${MAX_RETRY_COUNT}... 成功"
      return 0
    fi

    if [[ $attempt -lt $MAX_RETRY_COUNT ]]; then
      print_info "   尝试 ${attempt}/${MAX_RETRY_COUNT}... 失败"
      print_info "   等待 ${RETRY_INTERVAL} 秒后重试..."
      sleep "$RETRY_INTERVAL"
    else
      print_info "   尝试 ${attempt}/${MAX_RETRY_COUNT}... 失败"
    fi

    attempt=$((attempt + 1))
  done

  print_error "下载失败，已重试 ${MAX_RETRY_COUNT} 次"
  echo ""
  print_info "💡 你可以尝试手动安装:"
  print_info "   git clone ${GIT_REPO_URL} ${INSTALL_DIR}"
  print_info "   export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
  echo ""
  exit 1
}

install_to_target_dir() {
  echo ""
  print_info "📦 安装到 ${INSTALL_DIR}..."

  if [[ -d "$INSTALL_DIR" ]]; then
    local backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$INSTALL_DIR" "$backup_dir"
    print_info "   已备份旧版本到: ${backup_dir}"
  fi

  mv "$TEMP_DIR/repo" "$INSTALL_DIR"

  rm -rf "$TEMP_DIR"
  TEMP_DIR=""

  print_success "完成!"
}

configure_path_if_needed() {
  echo ""
  if prompt_yes_no "是否自动配置环境变量?" true; then
    configure_path
  else
    print_info "跳过环境变量配置"
    print_info "💡 你可以手动添加: export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
  fi
}

configure_path() {
  detect_user_shell
  print_info "   检测到 shell: ${USER_SHELL}"

  if is_path_already_configured; then
    print_warning "   PATH 已在 ${SHELL_CONFIG_FILE} 中配置"
    return 0
  fi

  local backup_file="${SHELL_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$SHELL_CONFIG_FILE" "$backup_file" 2>/dev/null || true

  {
    echo ""
    echo "$PATH_CONFIG_START_MARKER"
    echo "export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
    echo "$PATH_CONFIG_END_MARKER"
  } >> "$SHELL_CONFIG_FILE"

  print_success "   已添加到 ${SHELL_CONFIG_FILE}"
  echo ""
  print_info "💡 请运行: source ${SHELL_CONFIG_FILE} 或重启终端使配置生效"
}

is_path_already_configured() {
  [[ -f "$SHELL_CONFIG_FILE" ]] && grep -q "$PATH_CONFIG_START_MARKER" "$SHELL_CONFIG_FILE"
}

start_git_toolkit() {
  echo ""
  print_info "🚀 启动 git-toolkit..."
  echo ""

  exec "${INSTALL_DIR}/bin/git-toolkit"
}

main() {
  print_welcome_banner
  detect_os_type
  check_dependencies
  check_existing_installation
  download_repository
  install_to_target_dir
  configure_path_if_needed
  start_git_toolkit
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
