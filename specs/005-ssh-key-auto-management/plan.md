# Git Toolkit - SSH 密钥自动化深度融合技术实现方案

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
| 布尔变量使用肯定形式 | 如 `is_expert_mode`、`has_ssh_key` |
| 一致的缩进 | 使用 2 空格缩进 |
| 合理的行长度 | 每行不超过 100 字符 |
| 函数文档注释 | 每个函数包含描述、参数、返回值、示例 |
| 解释"为什么"而非"是什么" | 注释说明设计决策的原因 |

### 2.2 可维护性 (Maintainability)

| 原则 | 落实方案 |
|------|----------|
| 单一职责原则 | 每个函数只做一件事，不超过 50 行 |
| 模块化设计 | 增强现有模块，新增专家模式判断逻辑 |
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
| 配置迁移容错 | 自动迁移前备份，失败时回滚 |

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
│   └── git-toolkit              # 主入口（需大幅更新）
├── src/
│   ├── constants.sh             # 常量定义（需更新）
│   ├── core/                    # 核心业务逻辑
│   │   ├── init.sh              # 初始化功能（已有）
│   │   ├── ssh.sh               # SSH 密钥管理（已有）
│   │   ├── account.sh           # 多账号管理（需大幅增强）
│   │   └── alias.sh             # Alias 管理（已有）
│   ├── ui/                      # 用户界面
│   │   ├── menu.sh              # 交互式菜单（需大幅更新）
│   │   ├── prompt.sh            # 用户输入处理（需增强）
│   │   └── account_wizard.sh    # 账号添加向导（需增强）
│   └── utils/                   # 工具函数
│       ├── logger.sh            # 日志工具（已有）
│       ├── config.sh            # 配置文件读写（需增强）
│       ├── backup.sh            # 备份工具（已有）
│       ├── git.sh               # Git 操作封装（已有）
│       ├── validation.sh        # 输入验证（已有）
│       ├── ssh_config.sh        # SSH config 管理（已有）
│       └── migration.sh         # 配置迁移（新增）
├── test/
│   ├── unit/                    # 单元测试
│   │   ├── test_logger.sh       # 已有
│   │   ├── test_validation.sh   # 已有
│   │   ├── test_git.sh          # 已有
│   │   ├── test_ssh_config.sh   # 已有
│   │   ├── test_config.sh       # 已有（需更新）
│   │   ├── test_account.sh      # 已有（需更新）
│   │   ├── test_menu.sh         # 新增
│   │   └── test_migration.sh    # 新增
│   └── integration/             # 集成测试
│       ├── test_account.sh      # 已有（需更新）
│       ├── test_ssh.sh          # 已有
│       └── test_migration.sh    # 新增
└── specs/005-ssh-key-auto-management/
    ├── spec.md
    └── plan.md                 # 本文档
```

### 3.1 模块依赖关系

```
bin/git-toolkit
  └─> src/ui/menu.sh
        ├─> src/ui/account_wizard.sh (增强)
        ├─> src/core/init.sh
        ├─> src/core/ssh.sh
        ├─> src/core/account.sh (大幅增强)
        ├─> src/core/alias.sh
        └─> src/utils/* (logger, config, backup, git, validation, ssh_config, migration)
              └─> src/constants.sh (增强)
```

---

## 4. 核心数据结构

### 4.1 专家模式标识

**环境变量**: `GIT_TOOLKIT_EXPERT_MODE`

**格式**: 布尔值（true/false）

```bash
# 启用专家模式
export GIT_TOOLKIT_EXPERT_MODE=true

# 禁用专家模式（默认）
unset GIT_TOOLKIT_EXPERT_MODE
# 或
export GIT_TOOLKIT_EXPERT_MODE=false
```

### 4.2 账号配置 (Account Config) - 保持不变

**文件位置**: `~/.git-toolkit/accounts/<account-name>.conf`

**格式**: Bash 变量赋值

```bash
# 必填字段
ACCOUNT_NAME="personal"
GIT_USER_NAME="张三"
GIT_USER_EMAIL="zhangsan@example.com"

# 可选字段
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"
DOMAINS=("github.com" "gitee.com")
DOMAIN_SSH_KEYS=(
  "github.com:$HOME/.ssh/id_ed25519_github"
  "gitee.com:$HOME/.ssh/id_ed25519_gitee"
)
```

### 4.3 迁移标记文件

**文件位置**: `~/.git-toolkit/.migration_v5`

**用途**: 标记配置已迁移到 v5 版本，避免重复迁移

```bash
# 内容示例
MIGRATION_VERSION="5"
MIGRATION_TIMESTAMP="2026-03-04T10:30:00Z"
```

### 4.4 内存数据结构

```bash
# 专家模式状态
is_expert_mode=false

# 密钥使用情况
declare -A KEY_USAGE_MAP=(
  ["/Users/zhangsan/.ssh/id_ed25519_personal"]="personal"
  ["/Users/zhangsan/.ssh/id_rsa_legacy"]="work,legacy"
)
```

---

## 5. 接口设计

### 5.1 新增配置迁移模块 (src/utils/migration.sh)

```bash
# 描述: 检查是否需要执行配置迁移
# 参数: 无
# 返回: 0 需要迁移，1 不需要迁移
check_migration_needed() {
  # 1. 检查迁移标记文件是否存在
  # 2. 如果不存在，返回 0（需要迁移）
  # 3. 如果存在，返回 1（不需要迁移）
}

# 描述: 执行配置迁移
# 参数: 无
# 返回: 0 成功，非 0 失败
run_migration() {
  # 1. 备份现有配置
  # 2. 创建迁移标记文件
  # 3. 记录迁移时间
}

# 描述: 回滚迁移（如果失败）
# 参数: 无
# 返回: 0 成功，非 0 失败
rollback_migration() {
  # 1. 从备份恢复配置
  # 2. 删除迁移标记文件
}
```

### 5.2 增强常量定义 (src/constants.sh)

```bash
# 新增常量
readonly EXPERT_MODE_ENV_VAR="GIT_TOOLKIT_EXPERT_MODE"
readonly MIGRATION_VERSION="5"
readonly MIGRATION_MARKER_FILE="$GIT_TOOLKIT_DIR/.migration_v${MIGRATION_VERSION}"
```

### 5.3 增强核心账号模块 (src/core/account.sh)

```bash
# 描述: 删除账号（增强版，支持删除 SSH 密钥）
# 参数:
#   $1 - 账号名称
# 返回: 0 成功，非 0 失败
delete_account() {
  local account_name="$1"
  # 1. 加载账号配置
  # 2. 显示即将删除的信息
  # 3. 询问是否删除 SSH 密钥
  # 4. 如果确认删除密钥，验证密钥归属
  # 5. 删除账号配置
  # 6. 如果需要，删除 SSH 密钥文件（公钥+私钥）
  # 7. 更新 SSH config
}

# 描述: 检查密钥是否被其他账号使用
# 参数:
#   $1 - 密钥路径
#   $2 - 当前账号名称（可选，排除当前账号）
# 返回: 0 被其他账号使用，1 未被使用
is_key_used_by_others() {
  local key_path="$1"
  local exclude_account="${2:-}"
  # 1. 遍历所有账号
  # 2. 检查密钥是否被其他账号使用
  # 3. 返回结果
}

# 描述: 显示公钥内容
# 参数:
#   $1 - 私钥路径
# 返回: 0 成功，非 0 失败
show_public_key() {
  local private_key_path="$1"
  # 1. 检查私钥是否存在
  # 2. 读取对应的公钥文件
  # 3. 如果公钥不存在，从私钥导出
  # 4. 显示公钥内容
}
```

### 5.4 增强账号向导模块 (src/ui/account_wizard.sh)

```bash
# 描述: 运行简化版账号添加向导（默认自动生成 SSH 密钥）
# 参数: 无
# 返回: 0 成功，非 0 失败
run_simplified_account_add_wizard() {
  # 1. 收集账号基本信息（名称、用户名、邮箱）
  # 2. 询问是否需要选择 SSH 密钥配置方式
  # 3. 默认直接自动生成 SSH 密钥
  # 4. 如果用户选择，提供选项：自动生成/选择已有/暂不配置
  # 5. 如果选择已有密钥，列出并选择
  # 6. 如果密钥已被使用，显示警告
  # 7. 收集域名列表
  # 8. 保存账号配置
  # 9. 生成 SSH config
  # 10. 始终显示公钥内容
}

# 描述: 简化版 SSH 密钥配置方式选择
# 参数: 无
# 返回: 选择结果（1=自动生成, 2=选择已有, 3=跳过）
prompt_simplified_ssh_key_option() {
  # 1. 显示简化版选项，默认自动生成
  # 2. 返回用户选择
}
```

### 5.5 增强菜单模块 (src/ui/menu.sh)

```bash
# 描述: 检查是否处于专家模式
# 参数: 无
# 返回: 0 是专家模式，1 不是
is_expert_mode() {
  # 1. 检查环境变量 GIT_TOOLKIT_EXPERT_MODE
  # 2. 返回结果
}

# 描述: 显示主菜单（根据专家模式显示不同选项）
# 参数: 无
# 返回: 0
show_main_menu() {
  # 1. 检查是否是专家模式
  # 2. 普通模式：不显示 SSH 密钥管理选项
  # 3. 专家模式：显示完整菜单
  # 4. 如果是专家模式，在标题中显示 "[专家模式]"
}

# 描述: 显示账号管理菜单
# 参数: 无
# 返回: 0
show_account_menu() {
  # 保持现有功能，无需修改
}
```

### 5.6 增强主入口 (bin/git-toolkit)

```bash
# 描述: 显示帮助信息（根据专家模式显示不同内容）
# 参数: 无
# 返回: 0
show_help() {
  # 1. 检查是否是专家模式
  # 2. 普通模式：不显示 ssh 命令
  # 3. 专家模式：显示完整命令列表
}

# 描述: 主函数（增强）
# 参数:
#   $@ - 命令行参数
# 返回: 0
main() {
  # 1. 检查并执行配置迁移
  # 2. 现有逻辑保持不变
  # 3. 根据专家模式调整菜单和帮助
}
```

---

## 6. 实现里程碑

### Milestone 1: 基础设施 (Day 1)
- [ ] 增强 src/constants.sh 新增专家模式和迁移相关常量
- [ ] 实现 src/utils/migration.sh 配置迁移模块
- [ ] 编写 migration.sh 单元测试
- [ ] 验证迁移功能

### Milestone 2: 专家模式支持 (Day 2)
- [ ] 实现 is_expert_mode 函数
- [ ] 更新 src/ui/menu.sh 根据专家模式显示不同菜单
- [ ] 更新 bin/git-toolkit 的 show_help 函数
- [ ] 编写菜单模块单元测试
- [ ] 验证专家模式切换

### Milestone 3: 账号向导简化 (Day 3)
- [ ] 增强 src/ui/account_wizard.sh 实现简化版向导
- [ ] 实现 prompt_simplified_ssh_key_option
- [ ] 实现 show_public_key 函数
- [ ] 更新 run_account_add_wizard 或创建新的简化版本
- [ ] 编写单元测试

### Milestone 4: 账号删除增强 (Day 4)
- [ ] 增强 src/core/account.sh 的 delete_account 函数
- [ ] 实现 is_key_used_by_others 函数
- [ ] 添加 SSH 密钥删除确认逻辑
- [ ] 验证密钥归属检查
- [ ] 编写单元测试

### Milestone 5: 集成测试 (Day 5)
- [ ] 更新 bin/git-toolkit 集成所有新功能
- [ ] 更新主菜单和帮助信息
- [ ] 完整的端到端集成测试
- [ ] 普通模式和专家模式切换测试
- [ ] 配置迁移测试

### Milestone 6: 测试与完善 (Day 6)
- [ ] 完整集成测试
- [ ] 边界情况测试（无密钥、重复密钥等）
- [ ] 易用性评估
- [ ] 代码审查

---

## 7. 风险与缓解措施

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| 配置迁移出错 | 高 | 低 | 迁移前备份，失败时自动回滚，提供手动恢复方案 |
| 专家模式判断错误 | 中 | 低 | 单元测试覆盖，环境变量值容错处理 |
| 删除 SSH 密钥误操作 | 高 | 中 | 双重确认，验证密钥归属，默认不删除 |
| 公钥显示失败 | 中 | 低 | 容错处理，提供备用方案（从私钥导出） |
| 向后兼容性问题 | 高 | 中 | 保持旧功能可用，逐步迁移，充分测试 |
| 用户困惑专家模式 | 中 | 中 | 文档说明，默认隐藏，环境变量启用 |

---

## 8. 测试策略

### 8.1 单元测试
- 使用 shunit2 或 ShellSpec 框架
- 覆盖 migration.sh 新增的迁移函数
- 覆盖 account.sh 增强的删除和密钥检查函数
- 覆盖 account_wizard.sh 简化向导函数
- 覆盖 menu.sh 专家模式判断
- Mock 外部命令（ssh-keygen、git）

### 8.2 集成测试
- 测试完整的简化账号添加流程
- 测试专家模式切换
- 测试配置迁移
- 测试账号删除（含密钥删除确认）
- 测试公钥显示
- 使用临时目录隔离测试环境

### 8.3 手工测试
- macOS 和 Linux 平台验证
- 边界情况测试（无密钥、重复密钥、手动编辑配置等）
- 易用性评估
- 与现有功能的兼容性测试
- 专家模式和普通模式切换测试

---

*最后更新: 2026-03-04*
