# Git Toolkit 包结构设计

## 概述

本文档定义了 `git-toolkit` 项目的代码组织方式，遵循模块化、单一职责原则，符合 constitution.md 中的脚本编写规范。

---

## 项目整体结构

```
git-toolkit/
├── bin/                          # 可执行文件目录
│   └── git-toolkit              # 主入口脚本
├── src/                          # 源代码目录
│   ├── core/                    # 核心功能模块
│   │   ├── init.sh              # 初始化功能
│   │   ├── ssh.sh               # SSH 密钥管理
│   │   ├── account.sh           # 多账号管理
│   │   └── alias.sh             # Alias 管理
│   ├── ui/                      # 用户界面模块
│   │   ├── menu.sh              # 交互式菜单
│   │   └── prompt.sh            # 用户输入处理
│   ├── utils/                   # 工具函数模块
│   │   ├── logger.sh            # 日志工具
│   │   ├── config.sh            # 配置文件读写
│   │   ├── backup.sh            # 备份工具
│   │   ├── git.sh               # Git 操作封装
│   │   └── validation.sh        # 输入验证
│   └── constants.sh             # 常量定义
├── lib/                          # 第三方库（如需要）
├── test/                         # 测试目录
│   ├── unit/                    # 单元测试
│   └── integration/             # 集成测试
├── docs/                         # 文档目录
├── specs/                        # 规格说明目录
│   └── 001-core-functionality/
│       ├── spec.md
│       ├── package-structure.md
│       └── api-sketch.md
├── constitution.md               # 脚本编写规范
├── README.md                     # 项目说明
└── .gitignore                    # Git 忽略文件
```

---

## 模块详细说明

### 1. bin/ 目录

**职责**: 存放可执行文件，作为用户直接调用的入口点。

#### bin/git-toolkit
- **主入口脚本**
- 解析命令行参数
- 调用 src/core/ 中的对应功能
- 设置全局环境和 trap 清理

---

### 2. src/core/ 目录

**职责**: 实现 spec.md 中定义的核心功能模块。

#### src/core/init.sh - 初始化功能
```bash
# 描述: 执行 Git 环境初始化
# 功能:
#   - 收集用户信息（用户名、邮箱）
#   - 配置 Git 基础设置
#   - 应用预设 alias
#   - 备份原有配置

init_git_environment() { ... }
configure_git_settings() { ... }
apply_default_aliases() { ... }
```

#### src/core/ssh.sh - SSH 密钥管理
```bash
# 描述: 管理 SSH 密钥的生成、配置和测试
# 功能:
#   - 生成 Ed25519 SSH 密钥
#   - 显示公钥内容并复制到剪贴板
#   - 提供平台添加指导
#   - 测试 SSH 连接

generate_ssh_key() { ... }
copy_public_key() { ... }
test_ssh_connection() { ... }
```

#### src/core/account.sh - 多账号管理
```bash
# 描述: 管理多个 Git 账号配置
# 功能:
#   - 添加/删除账号
#   - 列出账号列表
#   - 切换全局账号
#   - 配置按域名/目录自动切换

add_account() { ... }
list_accounts() { ... }
switch_account() { ... }
delete_account() { ... }
setup_domain_switching() { ... }
```

#### src/core/alias.sh - Alias 管理
```bash
# 描述: 管理 Git alias 配置
# 功能:
#   - 应用预设 alias
#   - 添加自定义 alias
#   - 删除 alias
#   - 列出当前 alias

apply_preset_aliases() { ... }
add_alias() { ... }
remove_alias() { ... }
list_aliases() { ... }
```

---

### 3. src/ui/ 目录

**职责**: 处理所有用户交互相关的逻辑。

#### src/ui/menu.sh - 交互式菜单
```bash
# 描述: 提供交互式菜单界面
# 功能:
#   - 显示主菜单
#   - 显示子菜单
#   - 处理用户选择

show_main_menu() { ... }
show_init_menu() { ... }
show_ssh_menu() { ... }
show_account_menu() { ... }
show_alias_menu() { ... }
```

#### src/ui/prompt.sh - 用户输入处理
```bash
# 描述: 封装用户输入获取和验证
# 功能:
#   - 获取文本输入
#   - 获取确认输入（yes/no）
#   - 获取选择输入
#   - 输入验证

prompt_text() { ... }
prompt_yes_no() { ... }
prompt_choice() { ... }
prompt_password() { ... }
```

---

### 4. src/utils/ 目录

**职责**: 提供通用的工具函数，供其他模块复用。

#### src/utils/logger.sh - 日志工具
```bash
# 描述: 提供分级日志功能
# 功能:
#   - DEBUG、INFO、WARN、ERROR 级别
#   - 带时间戳的格式化输出
#   - 颜色输出（如支持）

log_debug() { ... }
log_info() { ... }
log_warn() { ... }
log_error() { ... }
```

#### src/utils/config.sh - 配置文件读写
```bash
# 描述: 读写配置文件
# 功能:
#   - 读取账号配置
#   - 保存账号配置
#   - 读取 alias 配置
#   - 保存 alias 配置

load_account_config() { ... }
save_account_config() { ... }
load_alias_config() { ... }
save_alias_config() { ... }
```

#### src/utils/backup.sh - 备份工具
```bash
# 描述: 备份和恢复配置
# 功能:
#   - 创建配置备份
#   - 列出备份
#   - 恢复备份

create_backup() { ... }
list_backups() { ... }
restore_backup() { ... }
```

#### src/utils/git.sh - Git 操作封装
```bash
# 描述: 封装 Git 配置操作
# 功能:
#   - 设置 Git 配置
#   - 获取 Git 配置
#   - 取消 Git 配置

git_set_config() { ... }
git_get_config() { ... }
git_unset_config() { ... }
git_has_config() { ... }
```

#### src/utils/validation.sh - 输入验证
```bash
# 描述: 验证用户输入
# 功能:
#   - 验证邮箱格式
#   - 验证用户名
#   - 验证域名
#   - 验证文件路径

validate_email() { ... }
validate_username() { ... }
validate_domain() { ... }
validate_path() { ... }
```

---

### 5. src/constants.sh - 常量定义

```bash
# 描述: 定义项目中使用的所有常量
# 内容:
#   - 目录路径
#   - 默认值
#   - 预设配置
#   - 版本信息

GIT_TOOLKIT_VERSION="1.0.0"
GIT_TOOLKIT_DIR="$HOME/.git-toolkit"
ACCOUNTS_DIR="$GIT_TOOLKIT_DIR/accounts"
BACKUP_DIR="$GIT_TOOLKIT_DIR/backup"
DEFAULT_BRANCH="main"
PRESET_ALIASES=(...)
```

---

## 设计原则

### 1. 单一职责
每个模块/函数只负责一件事，符合 constitution.md 中的要求。

### 2. 模块化
功能按领域划分，core 模块专注业务逻辑，ui 模块处理交互，utils 提供通用能力。

### 3. 可测试性
模块间通过清晰的接口交互，便于单元测试。

### 4. 可扩展性
新增功能只需在对应目录下添加新文件，无需修改现有代码。

### 5. 配置与代码分离
所有可变配置存储在 `~/.git-toolkit/` 目录下，代码中只保留默认值。

---

## 模块依赖关系

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

## 用户配置目录结构 (~/.git-toolkit/)

```
~/.git-toolkit/
├── config.sh          # 全局配置
├── accounts/
│   ├── personal.conf  # 个人账号配置
│   └── work.conf      # 工作账号配置
├── aliases            # Alias 配置
└── backup/            # 备份目录
    ├── gitconfig.20260303-120000.bak
    └── ...
```
