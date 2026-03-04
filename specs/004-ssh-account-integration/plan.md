# Git Toolkit - SSH 密钥与 Git 账号整合技术实现方案

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
- `ssh-keygen` - SSH 密钥生成工具
- 标准 Unix 工具（date, mkdir, cp, rm, sed, grep 等）

---

## 2. "合宪性"审查

本方案严格遵循 `constitution.md` 中的所有核心原则。

### 2.1 可读性 (Readability)

| 原则 | 落实方案 |
|------|----------|
| 使用有意义的名称 | 所有变量和函数使用 `snake_case`，清晰表达用途 |
| 布尔变量使用肯定形式 | 如 `is_compatible`、`has_domain_key` |
| 一致的缩进 | 使用 2 空格缩进 |
| 合理的行长度 | 每行不超过 100 字符 |
| 函数文档注释 | 每个函数包含描述、参数、返回值、示例 |
| 解释"为什么"而非"是什么" | 注释说明设计决策的原因 |

### 2.2 可维护性 (Maintainability)

| 原则 | 落实方案 |
|------|----------|
| 单一职责原则 | 每个函数只做一件事，不超过 50 行 |
| 模块化设计 | 增强现有模块，新增 UI 交互流程 |
| 避免深层嵌套 | 嵌套不超过 3 层，使用提前返回 |
| 配置与代码分离 | 配置存储在 `~/.git-toolkit/`，代码只保留默认值 |
| 默认值处理 | 所有变量提供合理默认值 |
| 版本控制友好 | 避免大文件重写，保持 diff 友好 |

### 2.3 健壮性 (Robustness)

| 原则 | 落实方案 |
|------|----------|
| 启用严格模式 | 所有脚本启用 `set -euo pipefail` |
| 输入验证 | 验证所有外部输入（邮箱、用户名、路径、域名等） |
| 参数数量检查 | 函数入口检查参数数量 |
| 检查命令执行结果 | 使用 `if ! command -v` 检查依赖命令 |
| 使用 trap 清理资源 | 脚本退出时清理临时文件 |
| 分级日志 | DEBUG/INFO/WARN/ERROR 四个级别 |
| 结构化日志 | 包含时间戳、级别、来源 |
| 新旧格式兼容 | 自动识别和处理新旧配置格式 |

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
│   │   ├── ssh.sh               # SSH 密钥管理（需增强）
│   │   ├── account.sh           # 多账号管理（需大幅增强）
│   │   └── alias.sh             # Alias 管理（已有）
│   ├── ui/                      # 用户界面
│   │   ├── menu.sh              # 交互式菜单（需更新）
│   │   ├── prompt.sh            # 用户输入处理（需增强）
│   │   └── account_wizard.sh    # 账号添加向导（新增）
│   └── utils/                   # 工具函数
│       ├── logger.sh            # 日志工具（已有）
│       ├── config.sh            # 配置文件读写（需增强）
│       ├── backup.sh            # 备份工具（已有）
│       ├── git.sh               # Git 操作封装（已有）
│       ├── validation.sh        # 输入验证（已有）
│       └── ssh_config.sh        # SSH config 管理（需增强）
├── test/
│   ├── unit/                    # 单元测试
│   │   ├── test_logger.sh       # 已有
│   │   ├── test_validation.sh   # 已有
│   │   ├── test_git.sh          # 已有
│   │   ├── test_ssh_config.sh   # 已有（需更新）
│   │   ├── test_config.sh       # 已有（需更新）
│   │   └── test_account.sh      # 已有（需更新）
│   └── integration/             # 集成测试
│       ├── test_account.sh      # 已有（需更新）
│       └── test_ssh.sh          # 已有（需更新）
└── specs/004-ssh-account-integration/
    ├── spec.md
    └── plan.md                 # 本文档
```

### 3.1 模块依赖关系

```
bin/git-toolkit
  └─> src/ui/menu.sh
        ├─> src/ui/account_wizard.sh (新增)
        ├─> src/core/init.sh
        ├─> src/core/ssh.sh (增强)
        ├─> src/core/account.sh (增强)
        └─> src/core/alias.sh
              └─> src/utils/* (logger, config, backup, git, validation, ssh_config)
                    └─> src/constants.sh
```

---

## 4. 核心数据结构

### 4.1 账号配置 (Account Config) - 增强版（支持域名-密钥映射）

**文件位置**: `~/.git-toolkit/accounts/<account-name>.conf`

**格式**: Bash 变量赋值

```bash
# 必填字段
ACCOUNT_NAME="personal"           # 账号唯一标识
GIT_USER_NAME="张三"               # Git 用户名
GIT_USER_EMAIL="zhangsan@example.com"  # Git 邮箱

# 可选字段 - 旧格式（向后兼容）
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"  # 默认 SSH 密钥路径
DOMAINS=("github.com" "gitee.com")  # 关联域名列表

# 可选字段 - 新格式（支持域名-密钥映射）
DOMAIN_SSH_KEYS=(
  "github.com:$HOME/.ssh/id_ed25519_github"
  "gitee.com:$HOME/.ssh/id_ed25519_gitee"
)
```

### 4.2 SSH 配置标识块

**文件位置**: `~/.ssh/config`

**格式**: 使用标识块包裹工具管理的配置

```ssh-config
# === git-toolkit managed start ===
Host github.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_github
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes

Host gitee.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_gitee
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
# === git-toolkit managed end ===
```

### 4.3 内存数据结构

```bash
# 账号配置（内存中）
declare -A ACCOUNT_CONFIG=(
  ["ACCOUNT_NAME"]="personal"
  ["GIT_USER_NAME"]="张三"
  ["GIT_USER_EMAIL"]="zhangsan@example.com"
  ["SSH_KEY_PATH"]="/Users/zhangsan/.ssh/id_ed25519_personal"
)

# 域名列表（内存中）
declare -a DOMAINS=("github.com" "gitee.com")

# 域名到密钥的映射（内存中）
declare -A DOMAIN_KEY_MAP=(
  ["github.com"]="/Users/zhangsan/.ssh/id_ed25519_github"
  ["gitee.com"]="/Users/zhangsan/.ssh/id_ed25519_gitee"
)

# SSH 密钥使用情况（内存中）
declare -A KEY_USAGE_MAP=(
  ["/Users/zhangsan/.ssh/id_ed25519_github"]="personal:github.com"
  ["/Users/zhangsan/.ssh/id_ed25519_gitee"]="personal:gitee.com"
)
```

---

## 5. 接口设计

### 5.1 新增 UI 模块接口 (src/ui/account_wizard.sh)

```bash
# 描述: 运行账号添加向导（一步完成 Git 信息和 SSH 密钥配置）
# 参数: 无
# 返回: 0 成功，非 0 失败
run_account_add_wizard() {
  # 1. 收集账号基本信息（名称、用户名、邮箱）
  # 2. 选择 SSH 密钥配置方式（生成/选择/跳过）
  # 3. 如果生成新密钥，收集密钥信息
  # 4. 如果选择已有密钥，列出并选择
  # 5. 收集域名列表
  # 6. 询问是否为不同域名配置不同密钥
  # 7. 如果是，为每个域名配置密钥
  # 8. 保存账号配置
  # 9. 生成 SSH config
  # 10. 显示公钥（如适用）
}

# 描述: 收集 SSH 密钥配置方式选择
# 参数: 无
# 返回: 选择结果（1=生成新密钥, 2=选择已有, 3=跳过）
prompt_ssh_key_option() {
  # 显示选项菜单，返回用户选择
}

# 描述: 生成新 SSH 密钥的交互流程
# 参数:
#   $1 - 账号名称（用于默认密钥名）
# 返回: 密钥文件路径，失败返回空
prompt_generate_ssh_key() {
  local account_name="$1"
  # 1. 询问密钥文件名（默认 id_ed25519_<account_name>）
  # 2. 询问密钥注释（可选，默认 <email>）
  # 3. 调用 generate_ssh_key
  # 4. 返回密钥路径
}

# 描述: 选择已有 SSH 密钥的交互流程
# 参数: 无
# 返回: 选中的密钥文件路径，取消返回空
prompt_select_ssh_key() {
  # 1. 调用 list_ssh_keys 获取可用密钥
  # 2. 显示列表供用户选择
  # 3. 返回选中的密钥路径
}

# 描述: 收集域名列表
# 参数: 无
# 返回: 域名数组（通过全局变量或输出）
prompt_domains() {
  # 1. 提示用户输入域名（空格分隔）
  # 2. 验证每个域名
  # 3. 返回域名数组
}

# 描述: 为域名配置密钥的交互流程
# 参数:
#   $1 - 域名列表
#   $2 - 默认密钥路径
# 返回: 域名-密钥映射数组
prompt_domain_key_mapping() {
  local -n domains="$1"
  local default_key="$2"
  # 1. 询问是否为不同域名配置不同密钥
  # 2. 如果是，为每个域名询问密钥
  # 3. 返回域名-密钥映射
}
```

### 5.2 增强账号管理模块接口 (src/core/account.sh)

```bash
# 描述: 添加新账号（增强版，支持域名-密钥映射）
# 参数:
#   $1 - 账号名称
#   $2 - 用户名
#   $3 - 邮箱
#   $4 - 默认 SSH 密钥路径（可选）
#   $5+ - 域名列表（可选，格式: domain[:key_path]）
# 返回: 0 成功，非 0 失败
add_account() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local default_ssh_key="${4:-}"
  shift 4
  local -a domain_entries=("${@:-}")
  # ... 原有逻辑 ...
  # 新增: 解析 domain_entries 分离域名和密钥
  # 新增: 保存 DOMAIN_SSH_KEYS 配置
  # 新增: 调用 add_ssh_config_for_account（增强版）
}

# 描述: 编辑账号
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
edit_account() {
  local account_name="$1"
  # 1. 加载现有配置
  # 2. 显示当前配置
  # 3. 依次询问是否修改各项
  # 4. 显示变更预览
  # 5. 确认后保存
  # 6. 重新生成 SSH config
}

# 描述: 列出所有账号（增强版，显示密钥使用情况）
# 参数: 无
# 返回: 0 成功，非 0 失败
list_accounts() {
  # ... 原有逻辑 ...
  # 新增: 显示默认密钥
  # 新增: 显示域名-密钥映射
}

# 描述: 加载账号配置（增强版，支持新旧格式）
# 参数:
#   $1 - 账号名称
#   $2 - 输出变量名前缀（可选）
# 返回: 0 成功，非 0 失败，设置全局变量或指定前缀的变量
load_account_config() {
  local account_name="$1"
  local var_prefix="${2:-}"
  # 1. 读取配置文件
  # 2. 兼容旧格式：如果有 SSH_KEY_PATH 和 DOMAINS 但没有 DOMAIN_SSH_KEYS
  # 3. 解析 DOMAIN_SSH_KEYS 构建 DOMAIN_KEY_MAP
}

# 描述: 保存账号配置（增强版）
# 参数:
#   $1 - 账号名称
#   $2 - 用户名
#   $3 - 邮箱
#   $4 - 默认 SSH 密钥路径（可选）
#   $5+ - 域名-密钥映射（格式: domain:key_path）
# 返回: 0 成功，非 0 失败
save_account_config() {
  local account_name="$1"
  local user_name="$2"
  local user_email="$3"
  local default_ssh_key="${4:-}"
  shift 4
  local -a domain_key_entries=("${@:-}")
  # 1. 备份现有配置
  # 2. 写入必填字段
  # 3. 如果有默认密钥，写入 SSH_KEY_PATH
  # 4. 提取域名列表写入 DOMAINS
  # 5. 如果有域名-密钥映射，写入 DOMAIN_SSH_KEYS
}
```

### 5.3 增强 SSH config 管理接口 (src/utils/ssh_config.sh)

```bash
# 描述: 为指定域名添加/更新 SSH 配置（增强版，支持新旧账号格式）
# 参数:
#   $1 - 域名
#   $2 - SSH 密钥路径
# 返回: 0 成功，非 0 失败
add_ssh_config() {
  local domain="$1"
  local ssh_key_path="$2"
  # ... 原有逻辑 ...
  # 保持现有功能不变
}

# 描述: 为账号的所有域名批量添加 SSH 配置（增强版，支持域名-密钥映射）
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
add_ssh_config_for_account() {
  local account_name="$1"
  # 1. 加载账号配置
  # 2. 如果有 DOMAIN_SSH_KEYS，使用域名-密钥映射
  # 3. 否则，使用默认密钥和 DOMAINS
  # 4. 为每个域名调用 add_ssh_config
}

# 描述: 获取 SSH 密钥使用情况
# 参数: 无
# 返回: 0 成功，非 0 失败，设置全局 KEY_USAGE_MAP
get_key_usage() {
  # 1. 遍历所有账号
  # 2. 对于每个账号，加载配置
  # 3. 记录默认密钥和域名-密钥映射
  # 4. 构建 KEY_USAGE_MAP
}
```

### 5.4 增强 SSH 模块接口 (src/core/ssh.sh)

```bash
# 描述: 列出 SSH 密钥（增强版，显示使用情况）
# 参数: 无
# 返回: 0 成功，非 0 失败
list_ssh_keys() {
  # ... 原有逻辑 ...
  # 新增: 调用 get_key_usage 获取使用情况
  # 新增: 显示每个密钥被哪些账号/域名使用
}

# 描述: 获取可用 SSH 密钥列表（用于选择）
# 参数: 无
# 返回: 密钥路径数组，通过全局变量或输出
get_available_ssh_keys() {
  # 1. 遍历 ~/.ssh 目录
  # 2. 识别 SSH 私钥文件
  # 3. 返回密钥路径数组
}
```

### 5.5 增强配置工具接口 (src/utils/config.sh)

```bash
# 描述: 解析域名-密钥映射字符串
# 参数:
#   $1 - 域名-密钥映射字符串（格式: "domain:key_path"）
#   $2 - 输出域名的变量名
#   $3 - 输出密钥路径的变量名
# 返回: 0 成功，非 0 失败
parse_domain_key_entry() {
  local entry="$1"
  local domain_var="$2"
  local key_var="$3"
  # 将 "domain:key_path" 拆分为 domain 和 key_path
}

# 描述: 构建域名-密钥映射字符串
# 参数:
#   $1 - 域名
#   $2 - 密钥路径
# 返回: 映射字符串
build_domain_key_entry() {
  local domain="$1"
  local key_path="$2"
  echo "$domain:$key_path"
}

# 描述: 从账号配置中提取域名列表（兼容新旧格式）
# 参数:
#   $1 - 账号配置文件路径
# 返回: 域名列表
extract_domains_from_config() {
  local config_file="$1"
  # 1. 尝试读取 DOMAIN_SSH_KEYS，提取域名
  # 2. 如果没有，读取 DOMAINS
}

# 描述: 获取指定域名的密钥路径（兼容新旧格式）
# 参数:
#   $1 - 账号配置文件路径
#   $2 - 域名
# 返回: 密钥路径，未找到返回空
get_key_for_domain() {
  local config_file="$1"
  local domain="$2"
  # 1. 尝试从 DOMAIN_SSH_KEYS 查找
  # 2. 如果没有，返回 SSH_KEY_PATH（默认密钥）
}
```

### 5.6 增强菜单模块接口 (src/ui/menu.sh)

```bash
# 账号管理菜单新增选项：
# 3) 编辑 Git 账号
# 7) 管理 SSH 密钥
```

### 5.7 增强常量定义 (src/constants.sh)

```bash
# 现有常量保持不变
# 无需新增常量
```

---

## 6. 实现里程碑

### Milestone 1: 基础设施增强 (Day 1-2)
- [ ] 增强 src/utils/config.sh 新增域名-密钥映射解析函数
- [ ] 增强 src/core/account.sh 的 load_account_config 和 save_account_config
- [ ] 增强 src/utils/ssh_config.sh 的 add_ssh_config_for_account
- [ ] 更新单元测试
- [ ] 验证新旧配置格式兼容

### Milestone 2: SSH 模块增强 (Day 3)
- [ ] 增强 src/core/ssh.sh 的 list_ssh_keys 显示使用情况
- [ ] 实现 get_available_ssh_keys 函数
- [ ] 实现 get_key_usage 函数
- [ ] 编写单元测试

### Milestone 3: 账号向导 UI (Day 4-5)
- [ ] 实现 src/ui/account_wizard.sh
- [ ] 实现 run_account_add_wizard
- [ ] 实现 prompt_ssh_key_option
- [ ] 实现 prompt_generate_ssh_key
- [ ] 实现 prompt_select_ssh_key
- [ ] 实现 prompt_domains
- [ ] 实现 prompt_domain_key_mapping
- [ ] 编写单元测试

### Milestone 4: 账号编辑功能 (Day 6)
- [ ] 实现 edit_account 函数
- [ ] 实现变更预览功能
- [ ] 更新 list_accounts 显示密钥使用情况
- [ ] 编写单元测试

### Milestone 5: 菜单集成 (Day 7)
- [ ] 更新 src/ui/menu.sh 新增账号编辑选项
- [ ] 更新 src/ui/menu.sh 新增 SSH 密钥管理选项
- [ ] 更新 bin/git-toolkit 集成新功能
- [ ] 集成测试

### Milestone 6: 测试与文档 (Day 8)
- [ ] 完整集成测试
- [ ] 新旧配置兼容性测试
- [ ] 边界情况测试
- [ ] 代码审查

---

## 7. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| 新旧配置格式转换出错 | 高 | 中 | 充分测试，提供重建 SSH config 功能，操作前备份 |
| DOMAIN_SSH_KEYS 解析复杂 | 中 | 中 | 单一职责函数，充分单元测试 |
| 手动编辑配置后工具出错 | 高 | 中 | 容错处理，验证配置格式，提供友好错误提示 |
| 向导流程用户体验不佳 | 中 | 中 | 提供清晰提示，支持默认值，允许跳过可选步骤 |
| Bash 版本兼容性差异 | 中 | 中 | 优先使用 POSIX 兼容语法，测试常见 Bash 版本 |
| macOS/Linux 命令差异 | 中 | 高 | 检查命令存在，提供替代方案 |

---

## 8. 测试策略

### 8.1 单元测试
- 使用 shunit2 或 ShellSpec 框架
- 覆盖 config.sh 新增的域名-密钥映射函数
- 覆盖 account.sh 增强的 load/save 函数
- 覆盖 ssh_config.sh 增强的功能
- 覆盖 account_wizard.sh 的各个提示函数
- Mock 外部命令（ssh-keygen、git）

### 8.2 集成测试
- 测试完整的账号添加向导流程
- 测试新旧配置格式的兼容性
- 测试账号编辑功能
- 测试 SSH config 生成
- 测试 SSH 密钥使用情况显示
- 使用临时目录隔离测试环境

### 8.3 手工测试
- macOS 和 Linux 平台验证
- 边界情况测试（手动编辑配置、无效配置等）
- 易用性评估
- 与现有功能的兼容性测试

---

*最后更新: 2026-03-04*
