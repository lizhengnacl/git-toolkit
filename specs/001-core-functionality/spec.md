# Git Toolkit - 核心功能规格说明

## 概述

`git-toolkit` 是一个帮助开发者快速配置和管理 Git 环境的工具集，包括新环境初始化、SSH 密钥自动化创建、多账号管理以及常用 alias 配置。

---

## 用户故事

### 故事 1：新环境快速初始化
作为一名开发者，当我拿到一台新电脑时，我希望通过一个命令就能完成 Git 的完整配置，包括用户名、邮箱、默认分支、换行符处理等，这样我就能立即开始工作，而不需要手动一个个配置。

### 故事 2：SSH 密钥自动化
作为一名开发者，我希望工具能帮我自动生成 SSH 密钥，并指导我如何添加到 GitHub/GitLab 等平台，这样我就不用记复杂的 ssh-keygen 命令了。

### 故事 3：多账号管理
作为一名开发者，我同时拥有个人账号和工作账号，可能还在不同的平台（GitHub、GitLab）有账号，我希望工具能帮我管理这些账号，并在我操作不同仓库时自动切换到对应的账号。

### 故事 4：常用 Git Alias
作为一名开发者，我希望有一套预设的实用 Git alias，来提高我的日常工作效率，同时也能根据需要自定义。

---

## 功能性需求

### 1. 新环境初始化配置
- **FR1.1** 提供交互式菜单引导用户完成初始化
- **FR1.2** 配置 Git 基础信息：user.name、user.email
- **FR1.3** 配置 Git 常用设置：
  - init.defaultBranch（默认 main）
  - core.autocrlf（macOS/Linux 设为 input，Windows 设为 true）
  - core.safecrlf（设为 warn）
  - core.editor（可选配置）
- **FR1.4** 配置预设的 Git alias（见 FR4）
- **FR1.5** 在修改现有配置前询问用户确认，并备份原有配置

### 2. SSH 自动化创建
- **FR2.1** 支持生成 Ed25519 类型的 SSH 密钥（推荐）
- **FR2.2** 允许用户自定义密钥名称和注释
- **FR2.3** 自动将公钥内容复制到剪贴板（如系统支持）
- **FR2.4** 提供各平台（GitHub、GitLab、Gitee 等）添加 SSH 密钥的指导链接
- **FR2.5** 提供测试 SSH 连接的功能

### 3. 多账号管理
- **FR3.1** 支持添加多个 Git 账号配置，每个账号包含：
  - 账号名称（标识）
  - user.name
  - user.email
  - SSH 密钥路径
  - 关联的域名列表（如 github.com、gitlab.com）
- **FR3.2** 支持按目录自动切换：为特定目录配置默认账号
- **FR3.3** 支持按 remote 域名自动切换：根据当前仓库的 remote URL 域名自动选择对应账号
- **FR3.4** 支持手动切换全局账号
- **FR3.5** 账号配置存储在 `~/.git-toolkit/accounts/` 目录下

### 4. 常见 Alias 配置
- **FR4.1** 提供基础 alias：
  - `st` = status
  - `co` = checkout
  - `br` = branch
  - `ci` = commit
  - `cp` = cherry-pick
- **FR4.2** 提供进阶 alias：
  - `lg` = 美化的日志（带图表、作者、日期）
  - `hist` = 简化的历史记录
  - `unstage` = reset HEAD --
  - `discard` = checkout HEAD --
  - `amend` = commit --amend
- **FR4.3** 允许用户查看、添加、删除自定义 alias
- **FR4.4** alias 配置存储在 `~/.git-toolkit/aliases`

### 5. 通用功能
- **FR5.1** 提供交互式菜单作为主要操作方式
- **FR5.2** 所有配置文件存储在 `~/.git-toolkit/` 目录下
- **FR5.3** 支持 macOS 和 Linux 系统
- **FR5.4** 在执行破坏性操作前备份原有配置
- **FR5.5** 提供清晰的帮助信息和操作提示

---

## 非功能性需求

### 1. 可维护性
- **NFR1.1** 使用 Shell 脚本实现，遵循项目 constitution.md 中的脚本编写规范
- **NFR1.2** 代码模块化，每个功能拆分为独立函数/文件
- **NFR1.3** 函数有清晰的文档注释

### 2. 健壮性
- **NFR2.1** 启用 `set -euo pipefail` 严格模式
- **NFR2.2** 验证所有用户输入
- **NFR2.3** 提供友好的错误提示
- **NFR2.4** 使用 trap 清理临时资源

### 3. 可移植性
- **NFR3.1** 使用 POSIX 兼容的 Shell 语法
- **NFR3.2** 不硬编码绝对路径
- **NFR3.3** 检查系统命令是否存在（如 ssh-keygen、git 等）

### 4. 易用性
- **NFR4.1** 交互式菜单清晰易懂
- **NFR4.2** 提供进度提示和成功/失败反馈
- **NFR4.3** 新手友好，包含必要的说明

---

## 验收标准

### AC1：初始化功能
- [ ] 运行工具后显示交互式菜单
- [ ] 选择初始化选项后，引导输入用户名和邮箱
- [ ] 确认后应用配置到 Git 全局配置
- [ ] 原有配置被备份
- [ ] 预设的 alias 被正确配置

### AC2：SSH 密钥生成
- [ ] 可以选择生成 Ed25519 密钥
- [ ] 可以自定义密钥文件名
- [ ] 公钥内容被显示并提示如何添加到平台
- [ ] 提供测试 SSH 连接的选项

### AC3：多账号管理
- [ ] 可以添加新账号配置
- [ ] 可以查看已配置的账号列表
- [ ] 可以手动切换全局账号
- [ ] 配置文件正确存储在 ~/.git-toolkit/accounts/
- [ ] 按域名切换功能正常工作

### AC4：Alias 管理
- [ ] 预设的基础和进阶 alias 可用
- [ ] 可以添加自定义 alias
- [ ] 可以删除 alias
- [ ] 配置变更立即生效

### AC5：整体质量
- [ ] 代码符合 constitution.md 规范
- [ ] 所有功能有清晰的错误处理
- [ ] 在 macOS 和 Linux 上正常运行
- [ ] 配置文件格式易于手动编辑

---

## 输出格式示例

### 1. 目录结构
```
~/.git-toolkit/
├── config.sh          # 主配置文件
├── accounts/
│   ├── personal.conf  # 个人账号配置
│   └── work.conf      # 工作账号配置
├── aliases            # Alias 配置
└── backup/            # 备份目录
```

### 2. 账号配置文件示例 (~/.git-toolkit/accounts/personal.conf)
```bash
ACCOUNT_NAME="personal"
GIT_USER_NAME="张三"
GIT_USER_EMAIL="zhangsan@example.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"
DOMAINS=("github.com" "gitee.com")
```

### 3. Alias 配置文件示例 (~/.git-toolkit/aliases)
```bash
[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  lg = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
  hist = log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
  unstage = reset HEAD --
  discard = checkout HEAD --
  amend = commit --amend
```

### 4. 交互式菜单示例
```
========================================
      Git Toolkit v1.0.0
========================================

请选择操作：

1) 初始化 Git 环境
2) 生成 SSH 密钥
3) 管理 Git 账号
4) 管理 Git Alias
5) 查看帮助
0) 退出

请输入选项 [0-5]: _
```
