# 脚本编写宪法

本文档定义了项目中所有脚本（Shell 等）的编写规范，以确保代码质量的一致性。

---

## 核心原则

### 1. 可读性 (Readability)

代码被阅读的次数远多于被编写的次数，可读性是首要原则。

#### 命名规范
- **使用有意义的名称**：变量、函数名应清晰表达其用途
  ```bash
  # Good
  backup_directory="/var/backups"
  max_retry_count=3

  # Bad
  dir="/var/backups"
  n=3
  ```

- **遵循语言惯例**：
  - Shell: 变量使用 `snake_case`，常量使用 `UPPER_SNAKE_CASE`

- **布尔变量使用肯定形式**：
  ```bash
  # Good
  is_enabled=true
  has_permission=false

  # Bad
  is_not_disabled=true
  ```

#### 代码格式
- **一致的缩进**：统一使用 2 空格或 4 空格（项目中保持一致）
- **合理的行长度**：每行不超过 100 字符，超长行应适当换行
- **空行分隔**：逻辑块之间使用空行分隔，提高可读性

#### 注释规范
- **解释"为什么"，而非"是什么"**：
  ```bash
  # Good: 解释原因
  # 使用 30 秒超时避免在弱网环境下长时间阻塞
  timeout=30

  # Bad: 重复代码含义
  # 设置超时为 30 秒
  timeout=30
  ```

- **函数必须有文档注释**：
  ```bash
  # 描述: 创建目录备份
  # 参数:
  #   $1 - 源目录路径
  #   $2 - 目标目录路径 (可选，默认为 /tmp/backup)
  # 返回: 0 成功，1 失败
  # 示例: backup_directory "/var/log" "/backup/logs"
  backup_directory() {
    ...
  }
  ```

---

### 2. 可维护性 (Maintainability)

代码应易于理解、修改和扩展。

#### 模块化设计
- **单一职责原则**：每个函数只做一件事
  ```bash
  # Good: 职责分离
  validate_input() { ... }
  process_data() { ... }
  save_result() { ... }

  # Bad: 一个函数做所有事
  do_everything() { ... }
  ```

- **函数长度限制**：单个函数不超过 50 行，超过时应拆分

- **避免深层嵌套**：嵌套不超过 3 层，使用提前返回
  ```bash
  # Good: 提前返回
  process_file() {
    [[ -f "$1" ]] || return 1
    [[ -r "$1" ]] || return 2

    # 主逻辑
    ...
  }

  # Bad: 深层嵌套
  process_file() {
    if [[ -f "$1" ]]; then
      if [[ -r "$1" ]]; then
        # 主逻辑
        ...
      fi
    fi
  }
  ```

#### 配置与代码分离
- **使用配置文件**：将可变参数提取到配置文件或环境变量
  ```bash
  # Good: 从配置读取
  source "${CONFIG_FILE:-/etc/app/config.sh}"

  # Bad: 硬编码
  db_host="localhost"
  db_port="5432"
  ```

- **默认值处理**：始终为变量提供合理的默认值
  ```bash
  log_level="${LOG_LEVEL:-INFO}"
  retry_count="${RETRY_COUNT:-3}"
  ```

#### 版本控制友好
- **避免大文件重写**：修改时保持 diff 友好
- **有意义的提交信息**：遵循 Conventional Commits 规范

---

### 3. 健壮性 (Robustness)

脚本应能优雅地处理异常情况，不会因意外输入而崩溃。

#### 输入验证
- **验证所有外部输入**：
  ```bash
  validate_path() {
    local path="$1"
    # 检查路径是否包含危险字符
    if [[ "$path" =~ \.\. ]] || [[ "$path" =~ ^/ ]]; then
      log_error "Invalid path: $path"
      return 1
    fi
    return 0
  }
  ```

- **参数数量检查**：
  ```bash
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <source> <destination>"
    exit 1
  fi
  ```

#### 错误处理
- **启用严格模式**（Shell）：
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  IFS=$'\n\t'
  ```

- **检查命令执行结果**：
  ```bash
  if ! command -v curl &>/dev/null; then
    log_error "curl is required but not installed"
    exit 1
  fi
  ```

- **使用 trap 清理资源**：
  ```bash
  cleanup() {
    rm -f "$temp_file"
  }
  trap cleanup EXIT
  ```

#### 日志记录
- **分级日志**：支持 DEBUG、INFO、WARN、ERROR 等级别
- **结构化日志**：包含时间戳、级别、来源
  ```bash
  log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
  }
  ```

#### 资源管理
- **设置超时**：网络请求和长时间操作必须有超时
- **限制重试**：重试次数和间隔应有上限
- **清理临时文件**：确保脚本退出时清理所有临时资源

---

### 4. 可移植性 (Portability)

脚本应能在不同环境中运行，不依赖特定系统配置。

#### Shebang 规范
- **使用 env 调用解释器**：
  ```bash
  #!/usr/bin/env bash
  ```

#### 路径处理
- **不硬编码路径**：
  ```bash
  # Good: 动态获取脚本目录
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Bad: 硬编码绝对路径
  SCRIPT_DIR="/home/user/scripts"
  ```

- **使用跨平台路径分隔符**：
  ```bash
  ```

#### 命令兼容性
- **优先使用 POSIX 兼容语法**：
  ```bash
  # Good: POSIX 兼容
  if [ -f "$file" ]; then ... fi

  # Better: Bash 特性但更安全
  if [[ -f "$file" ]]; then ... fi
  ```

- **检查命令是否存在**：
  ```bash
  if command -v gsed &>/dev/null; then
    SED_CMD="gsed"  # macOS with GNU sed
  else
    SED_CMD="sed"
  fi
  ```

#### 环境假设
- **不假设特定用户或主机名**
- **不假设特定时区**：使用 UTC 或明确指定时区
- **不假设特定语言环境**：
  ```bash
  # 强制使用 C 语言环境以确保一致的行为
  export LC_ALL=C
  ```

---

## 代码审查检查清单

在提交脚本前，请确认以下各项：

### 可读性
- [ ] 变量和函数命名清晰有意义
- [ ] 复杂逻辑有注释说明
- [ ] 代码格式统一，缩进正确

### 可维护性
- [ ] 函数职责单一，长度适中
- [ ] 配置与代码分离
- [ ] 无重复代码（DRY 原则）

### 健壮性
- [ ] 已启用 `set -euo pipefail`（Shell）
- [ ] 所有外部输入已验证
- [ ] 有适当的错误处理和日志
- [ ] 资源有清理机制（trap）
- [ ] 关键操作有超时限制

### 可移植性
- [ ] 使用 `#!/usr/bin/env` shebang
- [ ] 无硬编码路径
- [ ] 考虑跨平台兼容性

---

## 参考资料

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [The Art of Command Line](https://github.com/jlevy/the-art-of-command-line)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

*最后更新: 2026-03-02*
