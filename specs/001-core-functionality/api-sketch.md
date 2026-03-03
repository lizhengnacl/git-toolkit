# Git Toolkit API 接口设计

## 概述

本文档描述 `git-toolkit` 对外暴露的主要接口，包括命令行接口（CLI）和核心函数接口，作为后续开发的参考。

---

## 1. 命令行接口（CLI）

### 1.1 主命令

```bash
git-toolkit [COMMAND] [OPTIONS]
```

如果不带任何参数运行，将进入交互式菜单模式。

### 1.2 子命令列表

| 命令 | 描述 |
|------|------|
| `init` | 初始化 Git 环境 |
| `ssh` | SSH 密钥管理 |
| `account` | Git 账号管理 |
| `alias` | Git Alias 管理 |
| `help` | 显示帮助信息 |
| `version` | 显示版本信息 |

---

### 1.3 init 命令 - 初始化 Git 环境

```bash
git-toolkit init [OPTIONS]
```

**选项**:
- `-n, --name <name>` - Git 用户名
- `-e, --email <email>` - Git 邮箱
- `-y, --yes` - 跳过确认，直接执行
- `--no-backup` - 不备份原有配置

**示例**:
```bash
# 交互式初始化
git-toolkit init

# 非交互式初始化
git-toolkit init --name "张三" --email "zhangsan@example.com" --yes
```

---

### 1.4 ssh 命令 - SSH 密钥管理

```bash
git-toolkit ssh [SUBCOMMAND] [OPTIONS]
```

**子命令**:
- `generate` - 生成新的 SSH 密钥
- `list` - 列出已有的 SSH 密钥
- `test` - 测试 SSH 连接

#### ssh generate
```bash
git-toolkit ssh generate [OPTIONS]
```

**选项**:
- `-t, --type <type>` - 密钥类型（默认: ed25519）
- `-f, --filename <name>` - 密钥文件名（默认: id_ed25519）
- `-c, --comment <comment>` - 密钥注释
- `--no-copy` - 不复制公钥到剪贴板

**示例**:
```bash
git-toolkit ssh generate --filename id_ed25519_personal --comment "zhangsan@example.com"
```

#### ssh list
```bash
git-toolkit ssh list
```

#### ssh test
```bash
git-toolkit ssh test [DOMAIN]
```

**示例**:
```bash
git-toolkit ssh test github.com
```

---

### 1.5 account 命令 - Git 账号管理

```bash
git-toolkit account [SUBCOMMAND] [OPTIONS]
```

**子命令**:
- `add` - 添加新账号
- `list` - 列出所有账号
- `switch` - 切换当前账号
- `delete` - 删除账号
- `current` - 显示当前账号

#### account add
```bash
git-toolkit account add [OPTIONS]
```

**选项**:
- `-n, --name <name>` - 账号名称（标识）
- `--user-name <name>` - Git 用户名
- `--user-email <email>` - Git 邮箱
- `--ssh-key <path>` - SSH 密钥路径
- `--domains <list>` - 关联域名列表（逗号分隔）

**示例**:
```bash
git-toolkit account add --name personal \
  --user-name "张三" \
  --user-email "zhangsan@example.com" \
  --ssh-key ~/.ssh/id_ed25519_personal \
  --domains github.com,gitee.com
```

#### account list
```bash
git-toolkit account list
```

#### account switch
```bash
git-toolkit account switch <account-name>
```

**示例**:
```bash
git-toolkit account switch work
```

#### account delete
```bash
git-toolkit account delete <account-name>
```

#### account current
```bash
git-toolkit account current
```

---

### 1.6 alias 命令 - Git Alias 管理

```bash
git-toolkit alias [SUBCOMMAND] [OPTIONS]
```

**子命令**:
- `apply` - 应用预设 alias
- `add` - 添加自定义 alias
- `remove` - 删除 alias
- `list` - 列出所有 alias

#### alias apply
```bash
git-toolkit alias apply [OPTIONS]
```

**选项**:
- `--basic` - 仅应用基础 alias
- `--full` - 应用所有预设 alias（默认）

#### alias add
```bash
git-toolkit alias add <alias-name> <alias-command>
```

**示例**:
```bash
git-toolkit alias add st status
```

#### alias remove
```bash
git-toolkit alias remove <alias-name>
```

#### alias list
```bash
git-toolkit alias list
```

---

## 2. 核心函数接口（供内部模块使用）

### 2.1 初始化模块 (src/core/init.sh)

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

---

### 2.2 SSH 模块 (src/core/ssh.sh)

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

---

### 2.3 账号管理模块 (src/core/account.sh)

```bash
# 描述: 添加新账号
# 参数:
#   $1 - 账号名称
#   $2 - 用户名
#   $3 - 邮箱
#   $4 - SSH 密钥路径
#   $5 - 域名列表（空格分隔）
# 返回: 0 成功，非 0 失败
add_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="$4"
  local domains=($5)
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

---

### 2.4 Alias 管理模块 (src/core/alias.sh)

```bash
# 描述: 应用预设 alias
# 参数:
#   $1 - 模式（basic/full）
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

---

### 2.5 工具函数接口

#### 日志工具 (src/utils/logger.sh)
```bash
log_debug() { local message="$1"; ...; }
log_info() { local message="$1"; ...; }
log_warn() { local message="$1"; ...; }
log_error() { local message="$1"; ...; }
```

#### Git 操作封装 (src/utils/git.sh)
```bash
# 设置 Git 配置
git_set_config() {
  local key="$1"
  local value="$2"
  local scope="${3:-global}"  # global/local/system
  ...
}

# 获取 Git 配置
git_get_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}

# 取消 Git 配置
git_unset_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}

# 检查配置是否存在
git_has_config() {
  local key="$1"
  local scope="${2:-global}"
  ...
}
```

#### 备份工具 (src/utils/backup.sh)
```bash
# 创建备份
create_backup() {
  local file_path="$1"
  ...
}

# 列出备份
list_backups() {
  local file_pattern="$1"
  ...
}

# 恢复备份
restore_backup() {
  local backup_path="$1"
  local target_path="$2"
  ...
}
```

#### 输入验证 (src/utils/validation.sh)
```bash
validate_email() { local email="$1"; ...; }
validate_username() { local username="$1"; ...; }
validate_domain() { local domain="$1"; ...; }
validate_path() { local path="$1"; ...; }
```

---

## 3. 配置文件接口

### 3.1 账号配置文件格式

位置: `~/.git-toolkit/accounts/<account-name>.conf`

```bash
# 账号名称（标识）
ACCOUNT_NAME="personal"

# Git 配置
GIT_USER_NAME="张三"
GIT_USER_EMAIL="zhangsan@example.com"

# SSH 密钥路径
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"

# 关联域名列表
DOMAINS=("github.com" "gitee.com")
```

### 3.2 Alias 配置文件格式

位置: `~/.git-toolkit/aliases`

```ini
[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  lg = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

---

## 4. 退出码约定

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 通用错误 |
| 2 | 参数错误 |
| 3 | 配置文件错误 |
| 4 | 权限错误 |
| 5 | 命令不存在 |
| 130 | 用户中断（Ctrl+C） |

---

## 5. 环境变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `GIT_TOOLKIT_DIR` | Git Toolkit 配置目录 | `~/.git-toolkit` |
| `GIT_TOOLKIT_LOG_LEVEL` | 日志级别（DEBUG/INFO/WARN/ERROR） | `INFO` |
| `NO_COLOR` | 禁用彩色输出 | 未设置 |
