# --- 核心原则导入 (最高优先级) ---
# 明确导入项目宪法，确保AI在思考任何问题前，都已加载核心原则。
@./constitution.md

# --- 核心使命与角色设定 ---
你是一个资深的运维工程师，正在协助我开发一个名为 "devops-context" 的工具。你的所有行动都必须严格遵守上面导入的项目宪法。

---

## 项目概述

本项目遵循脚本编写的四大核心原则：**可读性**、**可维护性**、**健壮性**、**可移植性**。所有 Shell 脚本必须符合本文档规范。

---

## 脚本模板

编写新的 Shell 脚本时，必须使用以下模板：

```bash
#!/usr/bin/env bash
#
# 描述: [脚本功能的简要描述]
# 作者: [作者]
# 日期: [YYYY-MM-DD]
# 用法: [使用方法]
# 依赖: [必需的命令或工具]
#

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# 常量定义
# ============================================================================

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="1.0.0"

# ============================================================================
# 默认配置（可通过环境变量覆盖）
# ============================================================================

LOG_LEVEL="${LOG_LEVEL:-INFO}"
DRY_RUN="${DRY_RUN:-false}"

# ============================================================================
# 日志函数
# ============================================================================

log_debug() { [[ "${LOG_LEVEL}" == "DEBUG" ]] && echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_info()  { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_warn()  { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# ============================================================================
# 工具函数
# ============================================================================

# 描述: 显示帮助信息
# 参数: 无
# 返回: 0
show_help() {
  cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] <arguments>

Description:
  [详细描述脚本功能]

Options:
  -h, --help     显示此帮助信息
  -v, --version  显示版本信息
  -n, --dry-run  模拟运行，不执行实际操作

Examples:
  ${SCRIPT_NAME} --option value
  ${SCRIPT_NAME} -h
EOF
}

# 描述: 显示版本信息
show_version() {
  echo "${SCRIPT_NAME} version ${VERSION}"
}

# 描述: 安全退出
# 参数:
#   $1 - 退出码 (默认 0)
exit_script() {
  local exit_code="${1:-0}"
  exit "${exit_code}"
}

# ============================================================================
# 清理函数
# ============================================================================

cleanup() {
  local exit_code=$?
  # 在此处添加清理逻辑
  log_debug "Cleanup completed with exit code: ${exit_code}"
  exit "${exit_code}"
}
trap cleanup EXIT

# ============================================================================
# 参数解析
# ============================================================================

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit_script 0
        ;;
      -v|--version)
        show_version
        exit_script 0
        ;;
      -n|--dry-run)
        DRY_RUN=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        show_help
        exit_script 1
        ;;
      *)
        break
        ;;
    esac
  done

  # 剩余参数
  # POSITIONAL_ARGS=("$@")
}

# ============================================================================
# 主函数
# ============================================================================

main() {
  parse_arguments "$@"

  log_info "Starting ${SCRIPT_NAME}..."

  # 主逻辑放这里

  log_info "${SCRIPT_NAME} completed successfully"
}

# ============================================================================
# 入口
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

---

## 强制规范

### 1. 脚本头部

```bash
# 必须使用 env 调用
#!/usr/bin/env bash

# 必须启用严格模式
set -euo pipefail
IFS=$'\n\t'
```

### 2. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 局部变量 | `snake_case` | `file_count` |
| 常量 | `UPPER_SNAKE_CASE` + `readonly` | `readonly MAX_RETRY=3` |
| 函数 | `snake_case` | `process_file()` |
| 私有函数 | `_leading_underscore` | `_internal_helper()` |
| 环境变量 | `UPPER_SNAKE_CASE` | `LOG_LEVEL` |

### 3. 变量处理

```bash
# 必须使用 local 声明局部变量
process_data() {
  local input_file="$1"
  local output_file="${2:-/tmp/output}"
  local temp_file

  # 使用双引号包裹变量
  if [[ -f "${input_file}" ]]; then
    temp_file="$(mktemp)"
    # ...
  fi
}

# 使用 ${var:-default} 提供默认值
timeout="${TIMEOUT:-30}"
```

### 4. 条件判断

```bash
# 必须使用 [[ ]] 而非 [ ]
# Good
if [[ -f "$file" ]]; then
  ...
fi

# Bad
if [ -f "$file" ]; then
  ...
fi

# 字符串比较
if [[ "$status" == "success" ]]; then ...

# 数值比较
if [[ "$count" -gt 0 ]]; then ...

# 正则匹配
if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then ...
```

### 5. 函数定义

```bash
# 必须包含文档注释
# 描述: [功能描述]
# 参数:
#   $1 - 参数1说明
#   $2 - 参数2说明 (可选)
# 返回: 0 成功, 1 失败
# 示例: function_name "arg1" "arg2"
function_name() {
  local param1="$1"
  local param2="${2:-default}"

  # 参数验证
  [[ -n "${param1}" ]] || { log_error "param1 is required"; return 1; }

  # 主逻辑
  ...

  return 0
}
```

### 6. 错误处理

```bash
# 检查命令是否存在
check_dependencies() {
  local deps=("curl" "jq" "git")
  for dep in "${deps[@]}"; do
    if ! command -v "${dep}" &>/dev/null; then
      log_error "Required command not found: ${dep}"
      return 1
    fi
  done
}

# 使用 || 处理错误
mkdir -p "$target_dir" || {
  log_error "Failed to create directory: $target_dir"
  exit 1
}

# 使用 set -e 时，可忽略特定命令的错误
allowed_to_fail || true
```

### 7. 资源清理

```bash
# 必须使用 trap 清理资源
cleanup() {
  local exit_code=$?
  [[ -f "${temp_file:-}" ]] && rm -f "${temp_file}"
  [[ -d "${temp_dir:-}" ]] && rm -rf "${temp_dir}"
  exit "${exit_code}"
}
trap cleanup EXIT INT TERM
```

### 8. 命令替换

```bash
# 必须使用 $() 而非反引号
# Good
current_date="$(date '+%Y-%m-%d')"
file_list="$(find . -name '*.sh')"

# Bad
current_date=`date '+%Y-%m-%d'`
```

---

## 最佳实践

### 字符串处理

```bash
# 字符串长度
[[ ${#str} -gt 0 ]] || return 1

# 字符串截取
filename="${filepath##*/}"      # 获取文件名
extension="${filename##*.}"     # 获取扩展名
basename="${filename%.*}"       # 去除扩展名
dirname="${filepath%/*}"        # 获取目录名

# 字符串替换
result="${str//old/new}"        # 全局替换
result="${str/old/new}"         # 首次替换
```

### 数组操作

```bash
# 定义数组
local files=("file1" "file2" "file3")

# 遍历数组
for file in "${files[@]}"; do
  process_file "$file"
done

# 数组长度
local count="${#files[@]}"

# 添加元素
files+=("file4")
```

### 安全执行命令

```bash
# 使用 curl 时设置超时
response="$(curl --silent --show-error --max-time 30 --connect-timeout 10 "$url")"

# 使用 timeout 限制命令执行时间
timeout 60 command_with_potential_hang

# 使用 mktemp 创建安全临时文件
temp_file="$(mktemp)"
temp_dir="$(mktemp -d)"
```

### 进程替换

```bash
# 避免子 shell 变量丢失问题
while IFS= read -r line; do
  process_line "$line"
done < <(some_command)

# 而非
some_command | while IFS= read -r line; do
  process_line "$line"  # 这里的变量修改不会影响外部
done
```

---

## Git 提交规范

本项目遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

### 提交格式

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### 类型 (type)

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | feat(script): add backup script |
| `fix` | Bug 修复 | fix(deploy): correct path handling |
| `docs` | 文档更新 | docs: update README |
| `style` | 代码格式（不影响功能） | style: fix indentation |
| `refactor` | 重构 | refactor(utils): simplify logic |
| `perf` | 性能优化 | perf: optimize file search |
| `test` | 测试相关 | test: add unit tests |
| `chore` | 构建/工具相关 | chore: update dependencies |
| `ci` | CI/CD 相关 | ci: add github workflow |
| `revert` | 回滚提交 | revert: undo feat xyz |

### 作用域 (scope)

常见作用域：
- `script` - 脚本文件
- `config` - 配置文件
- `deploy` - 部署相关
- `utils` - 工具函数
- `docs` - 文档

### 提交示例

```bash
# 功能新增
git commit -m "feat(backup): add incremental backup support"

# Bug 修复
git commit -m "fix(sync): handle file permission errors"

# 破坏性变更
git commit -m "feat(api): redesign config format

BREAKING CHANGE: config file format changed from JSON to YAML"
```

---

## 代码审查检查清单

编写或审查 Shell 脚本时，必须确认：

### 基础检查
- [ ] 使用 `#!/usr/bin/env bash` shebang
- [ ] 启用 `set -euo pipefail`
- [ ] 脚本有完整的头部注释
- [ ] 使用 `readonly` 声明常量

### 命名与格式
- [ ] 变量使用 `snake_case`
- [ ] 常量使用 `UPPER_SNAKE_CASE`
- [ ] 函数有文档注释
- [ ] 缩进一致（2 或 4 空格）

### 安全性
- [ ] 所有变量用双引号包裹
- [ ] 使用 `[[ ]]` 进行条件判断
- [ ] 外部输入已验证
- [ ] 有 `trap cleanup EXIT`

### 健壮性
- [ ] 检查依赖命令是否存在
- [ ] 网络操作有超时设置
- [ ] 有适当的日志输出
- [ ] 错误信息输出到 stderr

---

## 禁止事项

以下行为被严格禁止：

```bash
# 禁止：使用未加引号的变量
echo $var                    # Bad
echo "$var"                  # Good

# 禁止：解析 ls 输出
for f in $(ls); do ...       # Bad
for f in *; do ...           # Good

# 禁止：使用反引号
date=`date`                  # Bad
date="$(date)"               # Good

# 禁止：硬编码路径
file="/home/user/data"       # Bad
file="${DATA_DIR:-/data}"    # Good

# 禁止：忽略命令返回值
rm "$file"                   # Bad
rm "$file" || log_warn "..." # Good

# 禁止：使用 cd 不检查
cd "$dir"                    # Bad
cd "$dir" || exit 1          # Good

# 禁止：无限循环无退出条件
while true; do ...           # Bad（无退出条件）
while true; do ...; break    # Good（有退出条件）
```

---

## 参考文件

- `constitution.md` - 核心原则详细说明
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell 静态分析工具

---

*最后更新: 2026-03-02*
