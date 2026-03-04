# Git Toolkit

一个帮助开发者快速配置和管理 Git 环境的工具集，包括新环境初始化、SSH 密钥自动化创建、多账号管理以及常用 alias 配置。

## 功能特性

- 🚀 **新环境快速初始化** - 一键配置 Git 完整配置
- 🔑 **SSH 密钥自动化** - 自动生成 Ed25519 密钥，指导添加到各平台
- 👥 **多账号管理** - 管理多个 Git 账号，支持自动切换
- ⚡ **常用 Alias** - 预设实用 Git 快捷命令
- 📋 **交互式菜单** - 友好的交互式界面

## 项目状态

本项目正在开发中，遵循 [constitution.md](./constitution.md) 脚本编写规范。

## 文档

- [spec.md](./specs/001-core-functionality/spec.md) - 核心功能规格说明
- [package-structure.md](./specs/001-core-functionality/package-structure.md) - 包结构设计
- [api-sketch.md](./specs/001-core-functionality/api-sketch.md) - API 接口设计
- [plan.md](./specs/001-core-functionality/plan.md) - 技术实现方案
- [tasks.md](./specs/001-core-functionality/tasks.md) - 开发任务列表

## 安装

### 快速安装（推荐）

使用 curl 安装：

```bash
curl -fsSL https://raw.githubusercontent.com/lizhengnacl/git-toolkit/main/install.sh | bash
```

或使用 wget 安装：

```bash
wget -qO- https://raw.githubusercontent.com/lizhengnacl/git-toolkit/main/install.sh | bash
```

### 手动安装

```bash
# 克隆项目
git clone <repo-url>
cd git-toolkit

# 添加到 PATH（可选）
export PATH="$PATH:$(pwd)/bin"
```

## 使用指南

### 交互式菜单（推荐）

直接运行工具进入交互式菜单：

```bash
git-toolkit
```

交互式菜单提供以下选项：
1. 初始化 Git 环境
2. 生成 SSH 密钥
3. 管理 Git 账号
4. 管理 Git Alias
5. 查看帮助
0. 退出

### 命令行接口

```bash
# 初始化 Git 环境
git-toolkit init [--name <name>] [--email <email>] [--yes]

# SSH 密钥管理
git-toolkit ssh generate [--type ed25519] [--filename <name>] [--comment <comment>]
git-toolkit ssh list
git-toolkit ssh test [domain]

# Git 账号管理
git-toolkit account add --name <name> --user-name <name> --user-email <email>
git-toolkit account list
git-toolkit account switch <account-name>
git-toolkit account delete <account-name>
git-toolkit account current

# Git Alias 管理
git-toolkit alias apply [--basic|--full]
git-toolkit alias add <alias-name> <alias-command>
git-toolkit alias remove <alias-name>
git-toolkit alias list

# 其他
git-toolkit help
git-toolkit version
```

### 使用示例

#### 1. 新环境初始化

```bash
# 交互式初始化
git-toolkit init

# 或使用命令行参数
git-toolkit init --name "张三" --email "zhangsan@example.com" --yes
```

#### 2. 生成 SSH 密钥

```bash
# 生成默认的 Ed25519 密钥
git-toolkit ssh generate

# 自定义密钥文件名
git-toolkit ssh generate --filename id_ed25519_personal --comment "zhangsan@example.com"

# 测试连接
git-toolkit ssh test github.com
```

#### 3. 管理多个 Git 账号

```bash
# 添加个人账号
git-toolkit account add --name personal \
  --user-name "张三" \
  --user-email "zhangsan@example.com" \
  --ssh-key ~/.ssh/id_ed25519_personal \
  --domains github.com,gitee.com

# 添加工作账号
git-toolkit account add --name work \
  --user-name "张三（工作）" \
  --user-email "zhangsan@company.com" \
  --ssh-key ~/.ssh/id_ed25519_work \
  --domains gitlab.company.com

# 切换账号
git-toolkit account switch work

# 查看当前账号
git-toolkit account current
```

#### 4. 配置 Git Alias

```bash
# 应用所有预设 alias
git-toolkit alias apply

# 仅应用基础 alias
git-toolkit alias apply --basic

# 添加自定义 alias
git-toolkit alias add st status

# 查看当前 alias
git-toolkit alias list

# 删除 alias
git-toolkit alias remove st
```

## 配置文件

所有配置存储在 `~/.git-toolkit/` 目录下：

```
~/.git-toolkit/
├── config.sh          # 全局配置
├── accounts/
│   ├── personal.conf  # 个人账号配置
│   └── work.conf      # 工作账号配置
├── aliases            # Alias 配置
└── backup/            # 备份目录
```

## 开发

### 目录结构

```
git-toolkit/
├── bin/                          # 可执行文件
├── src/                          # 源代码
│   ├── constants.sh             # 常量定义
│   ├── core/                    # 核心功能
│   │   ├── init.sh              # 初始化
│   │   ├── ssh.sh               # SSH 管理
│   │   ├── account.sh           # 账号管理
│   │   └── alias.sh             # Alias 管理
│   ├── ui/                      # 用户界面
│   │   ├── menu.sh              # 交互式菜单
│   │   └── prompt.sh            # 输入处理
│   └── utils/                   # 工具函数
│       ├── logger.sh            # 日志
│       ├── config.sh            # 配置读写
│       ├── backup.sh            # 备份工具
│       ├── git.sh               # Git 操作
│       └── validation.sh        # 输入验证
├── test/                         # 测试
│   ├── unit/                    # 单元测试
│   └── integration/             # 集成测试
└── specs/                        # 规格说明
```

### 运行测试

```bash
# 运行 validation 模块测试
test/unit/test_validation.sh

# 运行 git 模块测试
test/unit/test_git.sh
```

## 技术栈

- **语言**: Bash Shell
- **目标平台**: macOS + Linux
- **测试框架**: 自定义 TDD 测试

## 许可证

MIT
