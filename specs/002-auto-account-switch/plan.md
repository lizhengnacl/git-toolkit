# Git Toolkit - 自动账号切换技术实现方案

## 1. 技术上下文总结

### 1.1 技术选型

| 类别 | 选型 | 说明 |
|------|------|------|
| **语言** | Bash Shell | 符合 spec.md 要求，跨平台性好，无需额外依赖 |
| **目标平台** | macOS + Linux | 优先支持这两个主流开发平台 |
| **配置管理** | Shell 脚本 + 纯文本文件 | 易于维护和手动编辑 |
| **日志** | 自定义分级日志系统 | DEBUG/INFO/WARN/ERROR |
| **SSH 配置管理** | 直接操作 ~/.ssh/config | 使用标识块包裹工具管理的配置 |

### 1.2 核心依赖

- `git` - Git 命令行工具
- 标准 Unix 工具（date, mkdir, cp, rm, sed, grep 等）

---

## 2. "合宪性"审查

本方案严格遵循 `constitution.md` 中的所有核心原则。

### 2.1 可读性 (Readability)

| 原则 | 落实方案 |
|------|----------|
| 使用有意义的名称 | 所有变量和函数使用 `snake_case`，清晰表达用途 |
| 布尔变量使用肯定形式 | 如 `is_installed`、`has_remote` |
| 一致的缩进 | 使用 2 空格缩进 |
| 合理的行长度 | 每行不超过 100 字符 |
| 函数文档注释 | 每个函数包含描述、参数、返回值、示例 |
| 解释"为什么"而非"是什么" | 注释说明设计决策的原因 |

### 2.2 可维护性 (Maintainability)

| 原则 | 落实方案 |
|------|----------|
| 单一职责原则 | 每个函数只做一件事，不超过 50 行 |
| 模块化设计 | 新增 auto_switch.sh 核心模块，功能独立 |
| 避免深层嵌套 | 嵌套不超过 3 层，使用提前返回 |
| 配置与代码分离 | 配置存储在 `~/.git-toolkit/`，代码只保留默认值 |
| 默认值处理 | 所有变量提供合理默认值 |
| 版本控制友好 | 避免大文件重写，保持 diff 友好 |

### 2.3 健壮性 (Robustness)

| 原则 | 落实方案 |
|------|----------|
| 启用严格模式 | 所有脚本启用 `set -euo pipefail` |
| 输入验证 | 验证所有外部输入（域名、路径等） |
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
│   └── git-toolkit              # 主入口（需更新）
├── src/
│   ├── constants.sh             # 常量定义（需更新）
│   ├── core/                    # 核心业务逻辑
│   │   ├── init.sh              # 初始化功能（已有）
│   │   ├── ssh.sh               # SSH 密钥管理（已有）
│   │   ├── account.sh           # 多账号管理（需增强）
│   │   ├── alias.sh             # Alias 管理（已有）
│   │   └── auto_switch.sh       # 自动切换功能（新增）
│   ├── ui/                      # 用户界面
│   │   ├── menu.sh              # 交互式菜单（需更新）
│   │   └── prompt.sh            # 用户输入处理（已有）
│   └── utils/                   # 工具函数
│       ├── logger.sh            # 日志工具（已有）
│       ├── config.sh            # 配置文件读写（需增强）
│       ├── backup.sh            # 备份工具（已有）
│       ├── git.sh               # Git 操作封装（需增强）
│       ├── validation.sh        # 输入验证（需增强）
│       └── ssh_config.sh        # SSH config 管理（新增）
├── test/
│   ├── unit/                    # 单元测试
│   │   ├── test_logger.sh       # 已有
│   │   ├── test_validation.sh   # 已有
│   │   ├── test_git.sh          # 已有
│   │   ├── test_ssh_config.sh   # 新增
│   │   └── test_auto_switch.sh  # 新增
│   └── integration/             # 集成测试
│       ├── test_account.sh      # 已有
│       └── test_auto_switch.sh  # 新增
└── specs/002-auto-account-switch/
    ├── spec.md
    └── plan.md                 # 本文档
```

### 3.1 模块依赖关系

```
bin/git-toolkit
  └─> src/ui/menu.sh
        ├─> src/core/init.sh
        ├─> src/core/ssh.sh
        ├─> src/core/account.sh
        ├─> src/core/alias.sh
        └─> src/core/auto_switch.sh (新增)
              └─> src/utils/* (logger, config, backup, git, validation, ssh_config)
                    └─> src/constants.sh
```

---

## 4. 核心数据结构

### 4.1 账号配置 (Account Config) - 增强版

**文件位置**: `~/.git-toolkit/accounts/<account-name>.conf`

**格式**: Bash 变量赋值

```bash
# 必填字段
ACCOUNT_NAME="personal"           # 账号唯一标识
GIT_USER_NAME="张三"               # Git 用户名
GIT_USER_EMAIL="zhangsan@example.com"  # Git 邮箱

# 可选字段
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"  # SSH 密钥路径
DOMAINS=("github.com" "*.gitee.com")  # 关联域名列表（支持通配符）
```

### 4.2 SSH 配置标识块

**文件位置**: `~/.ssh/config`

**格式**: 使用标识块包裹工具管理的配置

```ssh-config
# === git-toolkit managed start ===
Host github.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host *.gitee.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_personal
  IdentitiesOnly yes
# === git-toolkit managed end ===
```

### 4.3 cd 钩子标识块

**文件位置**: `~/.zshrc` 或 `~/.bashrc`

**格式**: 使用标识块包裹工具管理的钩子

```bash
# === git-toolkit auto-switch start ===
_git_toolkit_auto_switch() {
  if [[ -d .git ]]; then
    git-toolkit account auto-switch 2>/dev/null || true
  fi
}

cd() {
  builtin cd "$@" || return $?
  _git_toolkit_auto_switch
}

# 初始检查当前目录
_git_toolkit_auto_switch
# === git-toolkit auto-switch end ===
```

### 4.4 内存数据结构

```bash
# 账号列表（内存中）
declare -a ACCOUNT_NAMES=("personal" "work")
declare -A ACCOUNT_MAP=(
  ["personal"]="/path/to/personal.conf"
  ["work"]="/path/to/work.conf"
)

# 域名到账号的映射（内存中）
declare -A DOMAIN_ACCOUNT_MAP=(
  ["github.com"]="personal"
  ["git.company.com"]="work"
)

# 通配符域名列表（内存中）
declare -a WILDCARD_DOMAINS=("*.gitee.com" "*.internal.company.com")
```

---

## 5. 接口设计

### 5.1 主入口接口更新 (bin/git-toolkit)

```bash
# account 子命令新增 auto-switch 和 hook 子命令
account)
  shift
  account_command "$@"
  ;;
```

### 5.2 新增核心模块接口 (src/core/auto_switch.sh)

```bash
# 描述: 自动切换到当前仓库对应的账号
# 参数: 无
# 返回: 0 成功，非 0 失败
auto_switch_account() {
  # 1. 检查是否为 Git 仓库
  # 2. 获取第一个 remote URL
  # 3. 提取域名
  # 4. 根据域名匹配账号
  # 5. 切换到匹配的账号
}

# 描述: 从 Git remote URL 中提取域名
# 参数:
#   $1 - remote URL
# 返回: 域名，失败返回空
extract_domain_from_url() {
  local url="$1"
  # 支持:
  # - https://github.com/user/repo.git
  # - git@github.com:user/repo.git
  # - ssh://git@github.com/user/repo.git
}

# 描述: 根据域名匹配账号
# 参数:
#   $1 - 域名
# 返回: 匹配的账号名称，无匹配返回空
match_account_by_domain() {
  local domain="$1"
  # 1. 先尝试精确匹配
  # 2. 再尝试通配符匹配
  # 3. 多个通配符匹配时返回第一个（按字母顺序）
}

# 描述: 检查通配符域名是否匹配
# 参数:
#   $1 - 通配符模式
#   $2 - 待匹配的域名
# 返回: 0 匹配，非 0 不匹配
match_wildcard_domain() {
  local pattern="$1"
  local domain="$2"
  # 将 *.example.com 转换为正则表达式 ^[^.]+\.example\.com$
}

# 描述: 安装 cd 钩子
# 参数: 无
# 返回: 0 成功，非 0 失败
install_cd_hook() {
  # 1. 检测用户的 shell（zsh/bash）
  # 2. 确定配置文件路径
  # 3. 检查是否已安装
  # 4. 备份配置文件
  # 5. 添加钩子代码（带标识块）
}

# 描述: 卸载 cd 钩子
# 参数: 无
# 返回: 0 成功，非 0 失败
uninstall_cd_hook() {
  # 1. 检测用户的 shell（zsh/bash）
  # 2. 确定配置文件路径
  # 3. 检查是否已安装
  # 4. 备份配置文件
  # 5. 删除标识块之间的内容
}

# 描述: 检查 cd 钩子是否已安装
# 参数: 无
# 返回: 0 已安装，非 0 未安装
is_cd_hook_installed() {
  # 检查配置文件中是否存在标识块
}
```

### 5.3 新增工具模块接口 (src/utils/ssh_config.sh)

```bash
# 描述: 为指定域名添加/更新 SSH 配置
# 参数:
#   $1 - 域名（支持通配符）
#   $2 - SSH 密钥路径
# 返回: 0 成功，非 0 失败
add_ssh_config() {
  local domain="$1"
  local ssh_key_path="$2"
  # 1. 备份 ~/.ssh/config
  # 2. 删除旧的配置（如果存在）
  # 3. 添加新的配置到标识块内
}

# 描述: 删除指定域名的 SSH 配置
# 参数:
#   $1 - 域名
# 返回: 0 成功，非 0 失败
remove_ssh_config() {
  local domain="$1"
  # 1. 备份 ~/.ssh/config
  # 2. 删除标识块内匹配的 Host 配置
}

# 描述: 为账号的所有域名批量添加 SSH 配置
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
add_ssh_config_for_account() {
  local account_name="$1"
  # 1. 加载账号配置
  # 2. 遍历所有域名
  # 3. 为每个域名调用 add_ssh_config
}

# 描述: 删除账号的所有 SSH 配置
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
remove_ssh_config_for_account() {
  local account_name="$1"
  # 1. 加载账号配置
  # 2. 遍历所有域名
  # 3. 为每个域名调用 remove_ssh_config
}

# 描述: 列出工具管理的所有 SSH 配置
# 参数: 无
# 返回: 0 成功，非 0 失败
list_managed_ssh_config() {
  # 读取标识块内的内容并显示
}

# 描述: 重建所有 SSH 配置（从账号配置同步）
# 参数: 无
# 返回: 0 成功，非 0 失败
rebuild_all_ssh_config() {
  # 1. 清空标识块内的内容
  # 2. 遍历所有账号
  # 3. 为每个账号调用 add_ssh_config_for_account
}
```

### 5.4 增强现有模块接口

#### 5.4.1 账号管理模块 (src/core/account.sh) - 增强

```bash
# 描述: 添加新账号（增强版，支持域名）
# 参数:
#   $1 - 账号名称
#   $2 - 用户名
#   $3 - 邮箱
#   $4 - SSH 密钥路径（可选）
#   $5+ - 域名列表（可选）
# 返回: 0 成功，非 0 失败
add_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local ssh_key_path="${4:-}"
  shift 4
  local -a domains=("${@:-}")
  # ... 原有逻辑 ...
  # 新增: 如果有 SSH 密钥和域名，自动添加 SSH 配置
  if [[ -n "$ssh_key_path" && ${#domains[@]} -gt 0 ]]; then
    add_ssh_config_for_account "$account_name"
  fi
}

# 描述: 删除账号（增强版）
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
delete_account() {
  local account_name="$1"
  # 新增: 删除对应的 SSH 配置
  remove_ssh_config_for_account "$account_name"
  # ... 原有逻辑 ...
}

# 描述: 列出所有账号（增强版，显示域名）
# 参数: 无
# 返回: 0 成功，非 0 失败
list_accounts() {
  # ... 原有逻辑 ...
  # 新增: 显示域名列表
  if [[ ${#DOMAINS[@]} -gt 0 ]]; then
    echo "  域名:   ${DOMAINS[*]}"
  fi
}
```

#### 5.4.2 Git 操作封装 (src/utils/git.sh) - 增强

```bash
# 描述: 获取当前仓库的第一个 remote 名称
# 参数: 无
# 返回: remote 名称，无 remote 返回空
git_get_first_remote() {
  git remote 2>/dev/null | head -n 1 || true
}

# 描述: 获取指定 remote 的 URL
# 参数:
#   $1 - remote 名称
# 返回: remote URL，失败返回空
git_get_remote_url() {
  local remote_name="$1"
  git remote get-url "$remote_name" 2>/dev/null || true
}

# 描述: 检查当前目录是否为 Git 仓库
# 参数: 无
# 返回: 0 是仓库，非 0 不是仓库
git_is_repository() {
  git rev-parse --is-inside-work-tree &>/dev/null
}
```

#### 5.4.3 输入验证 (src/utils/validation.sh) - 增强

```bash
# 描述: 验证域名（支持通配符）
# 参数:
#   $1 - 域名
# 返回: 0 有效，非 0 无效
validate_domain() {
  local domain="$1"
  # 支持通配符 *.example.com 或 git.*
  if [[ "$domain" == *"*"* ]]; then
    # 验证通配符格式
    [[ "$domain" =~ ^\*\.[a-zA-Z0-9.-]+$ ]] || [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.\*$ ]]
  else
    # 验证普通域名格式
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]
  fi
}
```

#### 5.4.4 配置文件读写 (src/utils/config.sh) - 增强

```bash
# 描述: 从账号配置文件加载所有账号
# 参数: 无
# 返回: 0 成功，非 0 失败，设置全局数组 ACCOUNT_NAMES
load_all_accounts() {
  # 遍历 $ACCOUNTS_DIR 下所有 .conf 文件
  # 填充 ACCOUNT_NAMES 数组
}

# 描述: 构建域名到账号的映射
# 参数: 无
# 返回: 0 成功，非 0 失败，设置全局映射 DOMAIN_ACCOUNT_MAP 和 WILDCARD_DOMAINS
build_domain_account_map() {
  # 遍历所有账号
  # 对于每个域名：
  #   - 如果是通配符，加入 WILDCARD_DOMAINS
  #   - 否则，加入 DOMAIN_ACCOUNT_MAP
}
```

#### 5.4.5 常量定义 (src/constants.sh) - 增强

```bash
# 新增常量
SSH_CONFIG_FILE="${HOME}/.ssh/config"
SSH_CONFIG_START_MARKER="# === git-toolkit managed start ==="
SSH_CONFIG_END_MARKER="# === git-toolkit managed end ==="

CD_HOOK_START_MARKER="# === git-toolkit auto-switch start ==="
CD_HOOK_END_MARKER="# === git-toolkit auto-switch end ==="
```

#### 5.4.6 菜单模块 (src/ui/menu.sh) - 增强

```bash
# 账号管理菜单新增选项
# 6) 安装/管理 cd 钩子
# 7) 查看 SSH 配置
```

---

## 6. 实现里程碑

### Milestone 1: 基础设施 (Day 1-2)
- [ ] 更新 constants.sh 添加新常量
- [ ] 实现 src/utils/ssh_config.sh SSH config 管理模块
- [ ] 增强 src/utils/validation.sh 域名验证（支持通配符）
- [ ] 增强 src/utils/git.sh Git 操作封装
- [ ] 增强 src/utils/config.sh 配置加载
- [ ] 编写单元测试

### Milestone 2: 自动切换核心逻辑 (Day 3-4)
- [ ] 实现 src/core/auto_switch.sh 自动切换模块
- [ ] 实现域名提取功能
- [ ] 实现通配符匹配功能
- [ ] 实现账号匹配功能
- [ ] 编写单元测试

### Milestone 3: cd 钩子管理 (Day 5)
- [ ] 实现 cd 钩子安装功能
- [ ] 实现 cd 钩子卸载功能
- [ ] 实现 cd 钩子状态检查功能
- [ ] 编写单元测试

### Milestone 4: 集成与菜单更新 (Day 6)
- [ ] 更新 src/core/account.sh 集成 SSH 配置管理
- [ ] 更新 src/ui/menu.sh 新增菜单选项
- [ ] 更新 bin/git-toolkit 新增子命令
- [ ] 集成测试

### Milestone 5: 测试与文档 (Day 7)
- [ ] 完整集成测试
- [ ] 边界情况测试
- [ ] 文档完善
- [ ] 代码审查

---

## 7. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| cd 钩子与用户现有 cd 函数冲突 | 高 | 中 | 使用标识块，安装前检查，提供卸载功能 |
| SSH config 被用户手动修改 | 高 | 中 | 使用标识块包裹，重建功能可同步 |
| 通配符匹配逻辑复杂出错 | 中 | 中 | 充分单元测试，清晰的匹配规则 |
| 切换到 global 级别影响其他仓库 | 高 | 高 | 按 spec 要求实现，提供清晰提示 |
| Bash 版本兼容性差异 | 中 | 中 | 优先使用 POSIX 兼容语法，测试常见 Bash 版本 |
| macOS/Linux sed 命令差异 | 中 | 高 | 检查命令存在，提供替代方案 |
| 现有 local 配置被覆盖 | 高 | 中 | 按 spec 要求实现，提供清晰提示 |

---

## 8. 测试策略

### 8.1 单元测试
- 使用 shunit2 或 ShellSpec 框架
- 覆盖 ssh_config.sh 所有函数
- 覆盖 auto_switch.sh 所有函数
- 覆盖增强的 validation.sh、git.sh、config.sh
- Mock 外部命令（git、sed）

### 8.2 集成测试
- 测试完整的自动切换工作流
- 测试 cd 钩子安装/卸载
- 测试 SSH 配置管理
- 使用临时目录隔离测试环境

### 8.3 手工测试
- macOS 和 Linux 平台验证
- 边界情况测试（无 remote、多 remote、无效 URL 等）
- 易用性评估
- 与现有功能的兼容性测试

---

*最后更新: 2026-03-03*
