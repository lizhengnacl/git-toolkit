# Git Toolkit - 远程脚本安装技术实现方案

## 1. 技术上下文总结

### 1.1 技术选型

| 类别 | 选型 | 说明 |
|------|------|------|
| **语言** | Bash Shell | 符合 spec.md 要求，无需额外依赖，跨平台性好 |
| **目标平台** | macOS + Linux | 优先支持这两个主流开发平台 |
| **下载方式** | git clone | 使用 Git 直接克隆仓库，便于后续更新 |
| **Shell 支持** | zsh + bash | 同时支持两种主流 Shell |
| **临时文件管理** | trap + mktemp | 确保临时资源被正确清理 |

### 1.2 核心依赖

- `git` - Git 命令行工具（用于克隆仓库）
- `curl` 或 `wget` - 至少一个用于下载脚本本身
- 标准 Unix 工具（date, mkdir, cp, rm, sed, grep 等）

---

## 2. "合宪性"审查

本方案严格遵循 `constitution.md` 中的所有核心原则。

### 2.1 可读性 (Readability)

| 原则 | 落实方案 |
|------|----------|
| 使用有意义的名称 | 所有变量和函数使用 `snake_case`，清晰表达用途，如 `is_git_toolkit_installed`、`detect_os_type` |
| 布尔变量使用肯定形式 | 如 `should_configure_path`、`has_curl_available` |
| 一致的缩进 | 使用 2 空格缩进，与项目现有代码保持一致 |
| 合理的行长度 | 每行不超过 100 字符，超长命令适当换行 |
| 函数文档注释 | 每个函数包含描述、参数、返回值、示例 |
| 解释"为什么"而非"是什么" | 注释说明设计决策的原因，如"使用浅克隆减少下载量" |

### 2.2 可维护性 (Maintainability)

| 原则 | 落实方案 |
|------|----------|
| 单一职责原则 | 每个函数只做一件事，不超过 50 行，如 `detect_os_type()` 只负责检测系统类型 |
| 模块化设计 | 将 install.sh 组织为多个逻辑函数，职责清晰分离 |
| 避免深层嵌套 | 嵌套不超过 3 层，使用提前返回简化逻辑 |
| 配置与代码分离 | 所有可配置参数（仓库 URL、重试次数、间隔时间）定义为常量，集中管理 |
| 默认值处理 | 所有变量提供合理默认值，如 `MAX_RETRY_COUNT=3`、`RETRY_INTERVAL=2` |
| 版本控制友好 | install.sh 作为单个文件，便于版本管理和 diff 查看 |

### 2.3 健壮性 (Robustness)

| 原则 | 落实方案 |
|------|----------|
| 启用严格模式 | install.sh 启用 `set -euo pipefail` 和 `IFS=$'\n\t'` |
| 输入验证 | 验证所有用户输入（y/n 确认），防止无效输入 |
| 参数数量检查 | 函数入口检查参数数量 |
| 检查命令执行结果 | 使用 `if ! command -v` 检查依赖命令（git、curl/wget） |
| 使用 trap 清理资源 | 脚本退出时清理临时目录和文件 |
| 重试机制 | 下载失败时自动重试最多 3 次，每次间隔 2 秒 |
| 友好错误提示 | 所有操作失败时有清晰的错误提示，给出解决建议 |

### 2.4 可移植性 (Portability)

| 原则 | 落实方案 |
|------|----------|
| 使用 env 调用解释器 | Shebang 为 `#!/usr/bin/env bash` |
| 不硬编码路径 | 动态获取用户主目录，使用 `$HOME` 而非绝对路径 |
| 优先使用 POSIX 兼容语法 | 同时利用 Bash 特性提高安全性 |
| 检查命令是否存在 | 优先检查 curl，回退到 wget |
| 不假设特定环境 | 不依赖特定用户、主机名、时区、语言，设置 `LC_ALL=C` 确保一致行为 |

---

## 3. 项目结构细化

```
git-toolkit/
├── bin/
│   └── git-toolkit              # 主入口（已有）
├── install.sh                    # 远程安装脚本（新增）
├── src/
│   ├── constants.sh             # 常量定义（已有）
│   ├── core/                    # 核心业务逻辑（已有）
│   ├── ui/                      # 用户界面（已有）
│   └── utils/                   # 工具函数（已有）
├── test/
│   ├── unit/                    # 单元测试
│   │   └── test_install.sh      # 安装脚本测试（新增）
│   └── integration/             # 集成测试
│       └── test_install.sh      # 安装流程集成测试（新增）
└── specs/003-remote-install/
    ├── spec.md
    └── plan.md                 # 本文档
```

### 3.1 模块依赖关系

```
install.sh (新增)
  └─> 独立脚本，无内部依赖
       使用系统命令: git, curl/wget, sed, grep, etc.

git clone → ~/.git-toolkit/
  └─> bin/git-toolkit
        └─> src/* (现有模块)
```

---

## 4. 核心数据结构

### 4.1 常量定义 (install.sh 内部)

```bash
# 仓库配置
GITHUB_REPO_OWNER="username"           # GitHub 用户名/组织名
GITHUB_REPO_NAME="git-toolkit"         # 仓库名称
GITHUB_BRANCH="main"                   # 默认分支
GIT_REPO_URL="https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git"

# 安装配置
INSTALL_DIR="${HOME}/.git-toolkit"     # 安装目录
MAX_RETRY_COUNT=3                       # 最大重试次数
RETRY_INTERVAL=2                        # 重试间隔（秒）

# Shell 配置标识块
PATH_CONFIG_START_MARKER="# === git-toolkit PATH start ==="
PATH_CONFIG_END_MARKER="# === git-toolkit PATH end ==="

# 颜色输出（ANSI 转义码）
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"
```

### 4.2 Shell 配置标识块

**文件位置**: `~/.zshrc` 或 `~/.bashrc`

**格式**: 使用标识块包裹工具管理的 PATH 配置

```bash
# === git-toolkit PATH start ===
export PATH="$PATH:$HOME/.git-toolkit/bin"
# === git-toolkit PATH end ===
```

### 4.3 临时数据结构

```bash
# 临时目录（用于克隆）
TEMP_DIR=""

# 检测结果
OS_TYPE=""                  # "macos" 或 "linux"
USER_SHELL=""               # "zsh" 或 "bash"
SHELL_CONFIG_FILE=""        # "~/.zshrc" 或 "~/.bashrc"
HAS_CURL=false
HAS_WGET=false
HAS_GIT=false
```

---

## 5. 接口设计

### 5.1 主入口流程 (install.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# 常量定义
# ... (见 4.1)

# 清理函数
cleanup() {
  # 清理临时目录
}
trap cleanup EXIT

# 主函数
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

main "$@"
```

### 5.2 核心函数接口

#### 5.2.1 UI 显示函数

```bash
# 描述: 打印欢迎横幅
# 参数: 无
# 返回: 无
print_welcome_banner() {
  # 使用彩色边框打印欢迎信息
}

# 描述: 打印成功消息
# 参数:
#   $1 - 消息内容
# 返回: 无
print_success() {
  echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}"
}

# 描述: 打印警告消息
# 参数:
#   $1 - 消息内容
# 返回: 无
print_warning() {
  echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}"
}

# 描述: 打印错误消息
# 参数:
#   $1 - 消息内容
# 返回: 无
print_error() {
  echo -e "${COLOR_RED}❌ $1${COLOR_RESET}" >&2
}

# 描述: 打印信息消息（无图标）
# 参数:
#   $1 - 消息内容
#   $2 - 缩进级别（可选，默认为 0）
# 返回: 无
print_info() {
  local message="$1"
  local indent="${2:-0}"
  local prefix=""
  for ((i=0; i<indent; i++)); do
    prefix+="  "
  done
  echo -e "${prefix}${message}"
}
```

#### 5.2.2 系统检测函数

```bash
# 描述: 检测操作系统类型
# 参数: 无
# 返回: 0 成功，设置全局变量 OS_TYPE
detect_os_type() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_TYPE="macos"
  else
    OS_TYPE="linux"
  fi
  print_success "检测系统: ${OS_TYPE}"
}

# 描述: 检测用户使用的 Shell
# 参数: 无
# 返回: 0 成功，设置全局变量 USER_SHELL 和 SHELL_CONFIG_FILE
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
    # 默认回退到 bash
    USER_SHELL="bash"
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
    print_warning "无法识别 Shell: ${shell_basename}，默认使用 bash"
  fi
}

# 描述: 检查依赖是否安装
# 参数: 无
# 返回: 0 成功，非 0 失败，设置全局变量 HAS_CURL/HAS_WGET/HAS_GIT
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

  local available_tools=("git")
  [[ $HAS_CURL == true ]] && available_tools+=("curl")
  [[ $HAS_WGET == true ]] && available_tools+=("wget")
  print_success "检查依赖: ${available_tools[*]} 均已安装"
}

# 描述: 打印依赖安装提示
# 参数:
#   $@ - 缺失的依赖列表
# 返回: 无
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
```

#### 5.2.3 安装检测与确认函数

```bash
# 描述: 检查是否已安装 git-toolkit
# 参数: 无
# 返回: 0 已安装，非 0 未安装
is_git_toolkit_installed() {
  [[ -d "$INSTALL_DIR" ]]
}

# 描述: 检查现有安装并询问用户
# 参数: 无
# 返回: 0 继续安装，非 0 用户取消
check_existing_installation() {
  if is_git_toolkit_installed; then
    print_warning "检测到已安装 git-toolkit"
    if ! prompt_yes_no "是否覆盖安装最新版本?" false; then
      print_info "用户取消安装，退出"
      exit 0
    fi
  fi
}

# 描述: 询问用户 yes/no 问题
# 参数:
#   $1 - 问题内容
#   $2 - 默认答案（true 或 false，可选，默认为 true）
# 返回: 0 用户选择 yes，非 0 用户选择 no
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
```

#### 5.2.4 下载与安装函数

```bash
# 描述: 下载（克隆）仓库
# 参数: 无
# 返回: 0 成功，非 0 失败
download_repository() {
  echo ""
  print_info "📥 下载最新代码..."

  # 创建临时目录
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

  # 所有重试都失败
  print_error "下载失败，已重试 ${MAX_RETRY_COUNT} 次"
  echo ""
  print_info "💡 你可以尝试手动安装:"
  print_info "   git clone ${GIT_REPO_URL} ${INSTALL_DIR}"
  print_info "   export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
  echo ""
  exit 1
}

# 描述: 安装到目标目录
# 参数: 无
# 返回: 0 成功，非 0 失败
install_to_target_dir() {
  echo ""
  print_info "📦 安装到 ${INSTALL_DIR}..."

  # 备份现有安装（如果存在）
  if [[ -d "$INSTALL_DIR" ]]; then
    local backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$INSTALL_DIR" "$backup_dir"
    print_info "   已备份旧版本到: ${backup_dir}"
  fi

  # 移动新代码到目标位置
  mv "$TEMP_DIR/repo" "$INSTALL_DIR"

  # 清理临时目录
  rm -rf "$TEMP_DIR"
  TEMP_DIR=""

  print_success "完成!"
}
```

#### 5.2.5 PATH 配置函数

```bash
# 描述: 询问用户是否配置 PATH 并执行
# 参数: 无
# 返回: 0 成功，非 0 失败
configure_path_if_needed() {
  echo ""
  if prompt_yes_no "是否自动配置环境变量?" true; then
    configure_path
  else
    print_info "跳过环境变量配置"
    print_info "💡 你可以手动添加: export PATH=\"\$PATH:${INSTALL_DIR}/bin\""
  fi
}

# 描述: 配置 PATH 环境变量
# 参数: 无
# 返回: 0 成功，非 0 失败
configure_path() {
  detect_user_shell
  print_info "   检测到 shell: ${USER_SHELL}"

  # 检查是否已配置
  if is_path_already_configured; then
    print_warning "   PATH 已在 ${SHELL_CONFIG_FILE} 中配置"
    return 0
  fi

  # 备份配置文件
  local backup_file="${SHELL_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$SHELL_CONFIG_FILE" "$backup_file" 2>/dev/null || true

  # 添加配置
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

# 描述: 检查 PATH 是否已配置
# 参数: 无
# 返回: 0 已配置，非 0 未配置
is_path_already_configured() {
  [[ -f "$SHELL_CONFIG_FILE" ]] && grep -q "$PATH_CONFIG_START_MARKER" "$SHELL_CONFIG_FILE"
}
```

#### 5.2.6 启动函数

```bash
# 描述: 启动 git-toolkit
# 参数: 无
# 返回: 0 成功，非 0 失败
start_git_toolkit() {
  echo ""
  print_info "🚀 启动 git-toolkit..."
  echo ""

  # 直接执行
  exec "${INSTALL_DIR}/bin/git-toolkit"
}
```

---

## 6. 实现里程碑

### Milestone 1: 基础设施 (Day 1)
- [ ] 创建 install.sh 基础框架（shebang、严格模式、常量定义）
- [ ] 实现清理函数和 trap
- [ ] 实现 UI 显示函数（彩色输出、欢迎横幅）
- [ ] 实现系统检测函数（detect_os_type）
- [ ] 实现依赖检查函数（check_dependencies）
- [ ] 编写单元测试

### Milestone 2: 用户交互 (Day 2)
- [ ] 实现确认询问函数（prompt_yes_no）
- [ ] 实现已安装检测（check_existing_installation）
- [ ] 实现 PATH 配置检测（is_path_already_configured）
- [ ] 编写单元测试

### Milestone 3: 下载与安装 (Day 3)
- [ ] 实现仓库下载函数（download_repository，含重试机制）
- [ ] 实现安装函数（install_to_target_dir，含备份）
- [ ] 实现 PATH 配置函数（configure_path）
- [ ] 编写单元测试

### Milestone 4: 集成与测试 (Day 4)
- [ ] 集成所有函数到 main 流程
- [ ] 实现启动函数（start_git_toolkit）
- [ ] 完整集成测试
- [ ] 边界情况测试

### Milestone 5: 完善与文档 (Day 5)
- [ ] 代码审查与优化
- [ ] 更新 README.md 添加安装命令
- [ ] 文档完善
- [ ] 最终测试

---

## 7. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| GitHub 访问不稳定导致下载失败 | 高 | 中 | 实现重试机制，最多 3 次，每次间隔 2 秒 |
| 用户取消安装后临时文件未清理 | 中 | 低 | 使用 trap 确保退出时清理临时目录 |
| Shell 配置文件被破坏 | 高 | 低 | 修改前自动备份配置文件 |
| 用户已有 git-toolkit 被误覆盖 | 高 | 中 | 检测到已安装时明确询问用户确认 |
| macOS/Linux 命令差异 | 中 | 高 | 使用 mktemp -d 的跨平台方式，检查命令存在 |
| Git clone 超时 | 中 | 中 | 使用 --depth 1 浅克隆减少下载量 |
| 非交互式环境（如 CI）下脚本挂起 | 高 | 低 | 检测标准输入是否为 tty，非 tty 时使用默认值 |
| 权限不足无法写入 ~/.git-toolkit | 高 | 中 | 提前检查写入权限，给出清晰提示 |

---

## 8. 测试策略

### 8.1 单元测试
- 使用 shunit2 或 ShellSpec 框架
- 覆盖所有辅助函数
- Mock 外部命令（git、curl、wget）
- 测试各种边界情况

### 8.2 集成测试
- 测试完整的安装流程
- 测试已安装时的覆盖场景
- 测试 PATH 配置功能
- 使用临时目录隔离测试环境
- 验证 ~/.git-toolkit 目录结构正确

### 8.3 手工测试
- macOS 和 Linux 平台验证
- zsh 和 bash 两种 Shell 测试
- 网络不稳定场景测试
- 权限不足场景测试
- 易用性评估

---

*最后更新: 2026-03-03*
