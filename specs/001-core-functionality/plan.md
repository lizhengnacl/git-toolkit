# Git Toolkit 技术实现方案

## 1. 技术上下文总结

### 1.1 技术选型

| 类别 | 选型 | 说明 |
|------|------|------|
| **语言** | Bash Shell | 符合 spec.md 要求，跨平台性好，无需额外依赖 |
| **目标平台** | macOS + Linux | 优先支持这两个主流开发平台 |
| **配置管理** | Shell 脚本 + 纯文本文件 | 易于维护和手动编辑 |
| **日志** | 自定义分级日志系统 | DEBUG/INFO/WARN/ERROR |

### 1.2 核心依赖

- `git` - Git 命令行工具
- `ssh-keygen` - SSH 密钥生成工具
- 标准 Unix 工具（date, mkdir, cp, rm 等）

---

## 2. "合宪性"审查

本方案严格遵循 `constitution.md` 中的所有核心原则。

### 2.1 可读性 (Readability)

| 原则 | 落实方案 |
|------|----------|
| 使用有意义的名称 | 所有变量和函数使用 `snake_case`，清晰表达用途 |
| 布尔变量使用肯定形式 | 如 `is_enabled`、`has_permission` |
| 一致的缩进 | 使用 2 空格缩进 |
| 合理的行长度 | 每行不超过 100 字符 |
| 函数文档注释 | 每个函数包含描述、参数、返回值、示例 |
| 解释"为什么"而非"是什么" | 注释说明设计决策的原因 |

### 2.2 可维护性 (Maintainability)

| 原则 | 落实方案 |
|------|----------|
| 单一职责原则 | 每个函数只做一件事，不超过 50 行 |
| 模块化设计 | 按功能拆分为 core/、ui/、utils/ 模块 |
| 避免深层嵌套 | 嵌套不超过 3 层，使用提前返回 |
| 配置与代码分离 | 配置存储在 `~/.git-toolkit/`，代码只保留默认值 |
| 默认值处理 | 所有变量提供合理默认值 |
| 版本控制友好 | 避免大文件重写，保持 diff 友好 |

### 2.3 健壮性 (Robustness)

| 原则 | 落实方案 |
|------|----------|
| 启用严格模式 | 所有脚本启用 `set -euo pipefail` |
| 输入验证 | 验证所有外部输入（邮箱、用户名、路径等） |
| 参数数量检查 | 函数入口检查参数数量 |
| 检查命令执行结果 | 使用 `if ! command -v` 检查依赖命令 |
| 使用 trap 清理资源 | 脚本退出时清理临时文件 |
| 分级日志 | DEBUG/INFO/WARN/ERROR 四个级别 |
| 结构化日志 | 包含时间戳、级别、来源 |

### 2.4 可移植性 (Portability)

| 原则 | 落实方案 |
|------|----------|
| 使用 env 调用解释器 | Shebang 为 `#!/usr/bin/env bash` |
| 不硬编码路径 | 动态获取脚本目录和用户主目录 |
| 优先使用 POSIX 兼容语法 | 同时利用 Bash 特性提高安全性 |
| 检查命令是否存在 | 处理 macOS/Linux 命令差异（如 sed/gsed） |
| 不假设特定环境 | 不依赖特定用户、主机名、时区、语言 |

---

## 3. 项目结构细化

```
git-toolkit/
├── bin/
│   └── git-toolkit              # 主入口（可执行）
├── src/
│   ├── constants.sh             # 常量定义（已创建）
│   ├── core/                    # 核心业务逻辑
│   │   ├── init.sh              # 初始化功能
│   │   ├── ssh.sh               # SSH 密钥管理
│   │   ├── account.sh           # 多账号管理
│   │   └── alias.sh             # Alias 管理
│   ├── ui/                      # 用户界面
│   │   ├── menu.sh              # 交互式菜单
│   │   └── prompt.sh            # 用户输入处理
│   └── utils/                   # 工具函数
│       ├── logger.sh            # 日志工具（已创建）
│       ├── config.sh            # 配置文件读写
│       ├── backup.sh            # 备份工具
│       ├── git.sh               # Git 操作封装
│       └── validation.sh        # 输入验证
├── test/
│   ├── unit/                    # 单元测试
│   │   ├── test_logger.sh
│   │   ├── test_validation.sh
│   │   └── test_git.sh
│   └── integration/             # 集成测试
│       └── test_init.sh
└── specs/001-core-functionality/
    ├── spec.md
    ├── package-structure.md
    ├── api-sketch.md
    └── plan.md                 # 本文档
```

### 3.1 模块依赖关系

```
bin/git-toolkit
  └─> src/ui/menu.sh
        ├─> src/core/init.sh
        ├─> src/core/ssh.sh
        ├─> src/core/account.sh
        └─> src/core/alias.sh
              └─> src/utils/* (logger, config, backup, git, validation)
                    └─> src/constants.sh
```

---

## 4. 核心数据结构

### 4.1 账号配置 (Account Config)

**文件位置**: `~/.git-toolkit/accounts/<account-name>.conf`

**格式**: Bash 变量赋值

```bash
# 必填字段
ACCOUNT_NAME="personal"           # 账号唯一标识
GIT_USER_NAME="张三"               # Git 用户名
GIT_USER_EMAIL="zhangsan@example.com"  # Git 邮箱

# 可选字段
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"  # SSH 密钥路径
DOMAINS=("github.com" "gitee.com")  # 关联域名列表
```

### 4.2 Alias 配置 (Alias Config)

**文件位置**: `~/.git-toolkit/aliases`

**格式**: Git 配置文件格式

```ini
[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  lg = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

### 4.3 全局配置 (Global Config)

**文件位置**: `~/.git-toolkit/config.sh`

**格式**: Bash 变量赋值

```bash
# 当前激活的账号
CURRENT_ACCOUNT="personal"

# 日志级别
LOG_LEVEL="INFO"
```

### 4.4 内存数据结构

```bash
# 账号列表（内存中）
declare -a ACCOUNT_NAMES=("personal" "work")
declare -A ACCOUNT_MAP=(
  ["personal"]="/path/to/personal.conf"
  ["work"]="/path/to/work.conf"
)

# Alias 列表（内存中）
declare -A ALIAS_MAP=(
  ["st"]="status"
  ["co"]="checkout"
)
```

---

## 5. 接口设计

### 5.1 主入口接口 (bin/git-toolkit)

```bash
# 描述: 主入口脚本，解析命令行参数或显示交互式菜单
# 用法: git-toolkit [COMMAND] [OPTIONS]
# 示例:
#   git-toolkit              # 交互式菜单
#   git-toolkit init         # 初始化
#   git-toolkit help         # 显示帮助

main() {
  local command="$1"
  case "$command" in
    init)
      shift
      init_command "$@"
      ;;
    ssh)
      shift
      ssh_command "$@"
      ;;
    account)
      shift
      account_command "$@"
      ;;
    alias)
      shift
      alias_command "$@"
      ;;
    help|--help|-h)
      show_help
      ;;
    version|--version|-v)
      show_version
      ;;
    "")
      show_main_menu
      ;;
    *)
      log_error "Unknown command: $command"
      show_help
      exit "$EXIT_ERROR_PARAMETER"
      ;;
  esac
}
```

### 5.2 核心模块接口

#### 5.2.1 初始化模块 (src/core/init.sh)

```bash
# 描述: 执行完整的 Git 环境初始化流程
# 参数: 无
# 返回: 0 成功，非 0 失败
init_git_environment()

# 描述: 配置 Git 基础设置
# 参数:
#   $1 - 用户名
#   $2 - 邮箱
# 返回: 0 成功，非 0 失败
configure_git_settings() {
  local user_name="$1"
  local user_email="$2"
  ...
}

# 描述: 应用默认的 Git alias
# 参数: 无
# 返回: 0 成功，非 0 失败
apply_default_aliases()
```

#### 5.2.2 SSH 模块 (src/core/ssh.sh)

```bash
# 描述: 生成 SSH 密钥
# 参数:
#   $1 - 密钥类型（ed25519/rsa）
#   $2 - 密钥文件名
#   $3 - 注释
# 返回: 0 成功，非 0 失败
generate_ssh_key() {
  local key_type="$1"
  local key_file="$2"
  local comment="$3"
  ...
}

# 描述: 复制公钥内容到剪贴板
# 参数:
#   $1 - 公钥文件路径
# 返回: 0 成功，非 0 失败
copy_public_key() {
  local public_key_path="$1"
  ...
}

# 描述: 测试 SSH 连接
# 参数:
#   $1 - 域名（如 github.com）
# 返回: 0 成功，非 0 失败
test_ssh_connection() {
  local domain="$1"
  ...
}
```

#### 5.2.3 账号管理模块 (src/core/account.sh)

```bash
# 描述: 添加新账号
# 参数:
#   $1 - 账号名称
#   $2 - 用户名
#   $3 - 邮箱
#   $4 - SSH 密钥路径（可选）
#   $5 - 域名列表（空格分隔，可选）
# 返回: 0 成功，非 0 失败
add_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="${4:-}"
  local domains=(${5:-})
  ...
}

# 描述: 列出所有账号
# 参数: 无
# 返回: 0 成功，非 0 失败
list_accounts()

# 描述: 切换到指定账号
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
switch_account() {
  local account_name="$1"
  ...
}

# 描述: 删除指定账号
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
delete_account() {
  local account_name="$1"
  ...
}

# 描述: 获取当前账号
# 参数: 无
# 返回: 当前账号名称
get_current_account()
```

#### 5.2.4 Alias 管理模块 (src/core/alias.sh)

```bash
# 描述: 应用预设 alias
# 参数:
#   $1 - 模式（basic/full），默认 full
# 返回: 0 成功，非 0 失败
apply_preset_aliases() {
  local mode="${1:-full}"
  ...
}

# 描述: 添加自定义 alias
# 参数:
#   $1 - alias 名称
#   $2 - alias 命令
# 返回: 0 成功，非 0 失败
add_alias() {
  local alias_name="$1"
  local alias_command="$2"
  ...
}

# 描述: 删除 alias
# 参数:
#   $1 - alias 名称
# 返回: 0 成功，非 0 失败
remove_alias() {
  local alias_name="$1"
  ...
}

# 描述: 列出所有 alias
# 参数: 无
# 返回: 0 成功，非 0 失败
list_aliases()
```

### 5.3 工具函数接口

#### 5.3.1 Git 操作封装 (src/utils/git.sh)

```bash
# 描述: 设置 Git 配置
# 参数:
#   $1 - 配置键
#   $2 - 配置值
#   $3 - 作用域（global/local/system），默认 global
# 返回: 0 成功，非 0 失败
git_set_config() {
  local key="$1"
  local value="$2"
  local scope="${3:-global}"
  ...
}

# 描述: 获取 Git 配置
# 参数:
#   $1 - 配置键
#   $2 - 作用域（global/local/system），默认 global
# 返回: 配置值，未找到返回空
git_get_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}

# 描述: 取消 Git 配置
# 参数:
#   $1 - 配置键
#   $2 - 作用域（global/local/system），默认 global
# 返回: 0 成功，非 0 失败
git_unset_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}

# 描述: 检查配置是否存在
# 参数:
#   $1 - 配置键
#   $2 - 作用域（global/local/system），默认 global
# 返回: 0 存在，非 0 不存在
git_has_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}
```

#### 5.3.2 备份工具 (src/utils/backup.sh)

```bash
# 描述: 创建文件备份
# 参数:
#   $1 - 源文件路径
#   $2 - 备份目录（可选，默认 $BACKUP_DIR）
# 返回: 备份文件路径，失败返回空
create_backup() {
  local source_path="$1"
  local backup_dir="${2:-$BACKUP_DIR}"
  ...
}

# 描述: 列出备份文件
# 参数:
#   $1 - 文件匹配模式（可选）
# 返回: 备份文件列表
list_backups() {
  local pattern="${1:-*}"
  ...
}

# 描述: 恢复备份
# 参数:
#   $1 - 备份文件路径
#   $2 - 目标文件路径
# 返回: 0 成功，非 0 失败
restore_backup() {
  local backup_path="$1"
  local target_path="$2"
  ...
}
```

#### 5.3.3 输入验证 (src/utils/validation.sh)

```bash
# 描述: 验证邮箱格式
# 参数:
#   $1 - 邮箱地址
# 返回: 0 有效，非 0 无效
validate_email() {
  local email="$1"
  ...
}

# 描述: 验证用户名
# 参数:
#   $1 - 用户名
# 返回: 0 有效，非 0 无效
validate_username() {
  local username="$1"
  ...
}

# 描述: 验证域名
# 参数:
#   $1 - 域名
# 返回: 0 有效，非 0 无效
validate_domain() {
  local domain="$1"
  ...
}

# 描述: 验证文件路径（安全检查）
# 参数:
#   $1 - 路径
# 返回: 0 有效，非 0 无效
validate_path() {
  local path="$1"
  ...
}
```

---

## 6. 实现里程碑

### Milestone 1: 基础设施 (Week 1)
- [ ] 创建所有目录和占位文件
- [ ] 实现 constants.sh 和 logger.sh
- [ ] 实现 validation.sh 验证工具
- [ ] 实现 git.sh Git 操作封装
- [ ] 编写单元测试

### Milestone 2: 初始化功能 (Week 2)
- [ ] 实现 init.sh 初始化模块
- [ ] 实现 backup.sh 备份工具
- [ ] 实现 ui/menu.sh 和 ui/prompt.sh
- [ ] 实现 bin/git-toolkit 主入口
- [ ] 集成测试

### Milestone 3: SSH 功能 (Week 3)
- [ ] 实现 ssh.sh SSH 密钥管理
- [ ] 实现 config.sh 配置文件读写
- [ ] 更新交互式菜单
- [ ] 集成测试

### Milestone 4: 账号和 Alias 管理 (Week 4)
- [ ] 实现 account.sh 多账号管理
- [ ] 实现 alias.sh Alias 管理
- [ ] 更新交互式菜单
- [ ] 完整集成测试
- [ ] 文档完善

---

## 7. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| Bash 版本兼容性差异 | 中 | 中 | 优先使用 POSIX 兼容语法，测试常见 Bash 版本 |
| macOS/Linux 命令差异 | 中 | 高 | 检查命令存在，提供替代方案（如 sed/gsed） |
| 现有 Git 配置被覆盖 | 高 | 中 | 操作前备份，询问用户确认 |
| 权限问题 | 中 | 低 | 检查文件权限，提供清晰错误提示 |
| 测试覆盖不足 | 高 | 中 | 优先实现核心功能测试，使用 ShellSpec 或 shunit2 |

---

## 8. 测试策略

### 8.1 单元测试
- 使用 shunit2 或 ShellSpec 框架
- 覆盖所有 utils 模块函数
- Mock 外部命令（git、ssh-keygen）

### 8.2 集成测试
- 测试完整工作流
- 使用临时目录隔离测试环境
- 验证配置文件读写

### 8.3 手工测试
- macOS 和 Linux 平台验证
- 边界情况测试（已有配置、无权限等）
- 易用性评估

---

*最后更新: 2026-03-03*
