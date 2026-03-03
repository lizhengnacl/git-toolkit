# Git Toolkit - 自动账号切换规格说明

## 概述

`git-toolkit` 的自动账号切换功能，通过检测当前 Git 仓库的 remote URL 域名，自动切换到对应的 Git 账号配置。该功能通过 shell 的 cd 钩子实现，在进入仓库目录时自动触发，并支持通配符域名匹配和 SSH 配置自动管理。

---

## 用户故事

### 故事 1：进入仓库时自动切换账号
作为一名同时拥有个人和工作账号的开发者，当我 cd 进入某个 Git 仓库目录时，我希望工具能自动检测该仓库的 remote URL，并切换到对应的账号配置，这样我就不会忘记手动切换账号而导致提交信息错误。

### 故事 2：通配符域名匹配
作为一名在企业内网有多个 Git 服务器的开发者，我希望能配置通配符域名（如 *.company.com），这样所有企业内网的 Git 仓库都能自动使用工作账号，而不需要为每个子域名单独配置。

### 故事 3：SSH 密钥自动管理
作为一名不想手动管理 SSH config 的开发者，我希望工具能自动为不同域名配置对应的 SSH 密钥，这样我就能用不同的 SSH 密钥访问不同的 Git 平台，而不需要手动编辑 ~/.ssh/config。

### 故事 4：cd 钩子自动安装
作为一名不想手动配置 shell 的开发者，我希望工具能自动将 cd 钩子安装到我的 shell 配置文件中，这样我就能立即使用自动切换功能，而不需要手动编辑 ~/.zshrc 或 ~/.bashrc。

---

## 功能性需求

### 1. cd 钩子自动安装与管理
- **FR1.1** 提供自动安装 cd 钩子的功能，支持检测并修改 ~/.zshrc 和 ~/.bashrc
- **FR1.2** 在 shell 配置文件中添加标识块，便于后续管理和卸载
- **FR1.3** 提供查看钩子安装状态的功能
- **FR1.4** 提供卸载 cd 钩子的功能

### 2. 基于 remote URL 的账号自动切换
- **FR2.1** cd 进入目录时，检测是否为 Git 仓库
- **FR2.2** 如果是 Git 仓库，获取第一个 remote 的 URL
- **FR2.3** 从 remote URL 中提取域名（支持 HTTPS 和 SSH 格式的 URL）
- **FR2.4** 根据域名匹配对应的账号配置
- **FR2.5** 如果没有匹配的账号或没有 remote，使用全局默认账号
- **FR2.6** 切换账号时设置为 global 级别
- **FR2.7** 如果仓库已有 local 级别的配置，直接覆盖
- **FR2.8** 切换成功后显示提示信息（显示使用的账号名称）

### 3. 通配符域名匹配
- **FR3.1** 账号配置支持 DOMAINS 数组，可包含多个域名
- **FR3.2** 域名匹配支持通配符（如 *.github.com、gitlab.*）
- **FR3.3** 通配符匹配规则：
  - `*` 匹配任意字符（除了点）
  - `*.example.com` 匹配 a.example.com、b.example.com，但不匹配 example.com
  - `git.*` 匹配 git.github.com、git.gitlab.com
- **FR3.4** 精确匹配优先级高于通配符匹配
- **FR3.5** 多个通配符都匹配时，使用第一个匹配的账号（按配置文件字母顺序）

### 4. SSH 配置自动管理
- **FR4.1** 为每个账号配置的域名自动添加/更新 ~/.ssh/config 条目
- **FR4.2** SSH config 条目格式：
  ```
  Host <domain>
    IdentityFile <ssh_key_path>
    IdentitiesOnly yes
  ```
- **FR4.3** 支持通配符域名的 SSH 配置
- **FR4.4** 在修改 ~/.ssh/config 前自动备份
- **FR4.5** 删除账号时，同步删除对应的 SSH config 条目
- **FR4.6** 提供查看工具管理的 SSH 配置的功能

### 5. 账号配置管理增强
- **FR5.1** 添加账号时支持输入多个域名（空格分隔）
- **FR5.2** 编辑账号时支持修改域名列表
- **FR5.3** 列出账号时显示关联的域名列表
- **FR5.4** 支持为账号配置优先级（可选，用于未来扩展）

### 6. 通用功能
- **FR6.1** 所有操作提供清晰的成功/失败提示
- **FR6.2** 在执行破坏性操作前备份相关配置文件
- **FR6.3** 遵循项目现有代码风格和架构

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
- **NFR2.5** 处理边界情况：无 remote、多 remote、无效 remote URL 等

### 3. 可移植性
- **NFR3.1** 使用 POSIX 兼容的 Shell 语法
- **NFR3.2** 不硬编码绝对路径
- **NFR3.3** 检查系统命令是否存在
- **NFR3.4** 支持 macOS 和 Linux 系统

### 4. 易用性
- **NFR4.1** cd 钩子安装过程简单清晰
- **NFR4.2** 自动切换时提供明确的提示信息
- **NFR4.3** 新手友好，包含必要的说明

### 5. 性能
- **NFR5.1** cd 钩子执行速度快，不明显影响 cd 命令的响应时间
- **NFR5.2** 避免在 cd 钩子中执行耗时操作

---

## 验收标准

### AC1：cd 钩子安装与管理
- [ ] 可以自动检测用户的 shell（zsh 或 bash）
- [ ] 可以将 cd 钩子安装到对应的 shell 配置文件
- [ ] 钩子安装后，重新加载 shell 配置即可生效
- [ ] 可以查看钩子的安装状态
- [ ] 可以卸载 cd 钩子
- [ ] 卸载后不影响 shell 配置文件的其他内容

### AC2：基于 remote URL 的自动切换
- [ ] cd 进入 Git 仓库时自动检测
- [ ] 能正确从 HTTPS URL 提取域名（如 https://github.com/user/repo.git → github.com）
- [ ] 能正确从 SSH URL 提取域名（如 git@github.com:user/repo.git → github.com）
- [ ] 能根据域名匹配到对应的账号
- [ ] 切换后 git config --global user.name 和 user.email 正确设置
- [ ] 无匹配账号或无 remote 时使用全局默认账号
- [ ] 仓库已有 local 配置时会被覆盖
- [ ] 切换成功后显示提示信息

### AC3：通配符域名匹配
- [ ] 支持配置 *.example.com 格式的通配符
- [ ] 通配符能正确匹配子域名
- [ ] 精确匹配优先级高于通配符匹配
- [ ] 多个通配符匹配时使用第一个匹配的账号

### AC4：SSH 配置自动管理
- [ ] 添加账号时自动在 ~/.ssh/config 添加对应域名的配置
- [ ] SSH 配置包含正确的 IdentityFile 和 IdentitiesOnly
- [ ] 修改账号时同步更新 SSH 配置
- [ ] 删除账号时同步删除对应的 SSH 配置
- [ ] 修改 ~/.ssh/config 前自动备份
- [ ] 可以查看工具管理的 SSH 配置条目

### AC5：账号配置管理增强
- [ ] 添加账号时可以输入多个域名
- [ ] 列出账号时显示关联的域名列表
- [ ] 域名列表正确保存到账号配置文件

### AC6：整体质量
- [ ] 代码符合 constitution.md 规范
- [ ] 所有功能有清晰的错误处理
- [ ] 在 macOS 和 Linux 上正常运行
- [ ] 配置文件格式易于手动编辑
- [ ] cd 钩子执行速度快，不明显影响用户体验

---

## 输出格式示例

### 1. 账号配置文件示例 (~/.git-toolkit/accounts/personal.conf)
```bash
ACCOUNT_NAME="personal"
GIT_USER_NAME="张三"
GIT_USER_EMAIL="zhangsan@example.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_personal"
DOMAINS=("github.com" "*.gitee.com")
```

### 2. 账号配置文件示例 (~/.git-toolkit/accounts/work.conf)
```bash
ACCOUNT_NAME="work"
GIT_USER_NAME="张三（工作）"
GIT_USER_EMAIL="zhangsan@company.com"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_work"
DOMAINS=("git.company.com" "*.internal.company.com")
```

### 3. 自动生成的 SSH config 示例 (~/.ssh/config)
```
# === git-toolkit managed start ===
Host github.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host *.gitee.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host git.company.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_work
  IdentitiesOnly yes

Host *.internal.company.com
  IdentityFile /Users/zhangsan/.ssh/id_ed25519_work
  IdentitiesOnly yes
# === git-toolkit managed end ===
```

### 4. cd 钩子示例（添加到 ~/.zshrc 或 ~/.bashrc）
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

### 5. 交互式菜单示例（账号管理菜单新增选项）
```
========================================
      Git 账号管理
========================================

请选择操作：

1) 添加 Git 账号
2) 列出 Git 账号
3) 切换 Git 账号
4) 删除 Git 账号
5) 查看当前账号
6) 安装/管理 cd 钩子
7) 查看 SSH 配置
0) 返回主菜单

请输入选项 [0-7]: _
```

### 6. 自动切换提示示例
```
$ cd ~/projects/personal-repo
✅ 已自动切换到账号: personal
   用户名: 张三
   邮箱:   zhangsan@example.com

$ cd ~/projects/work-repo
✅ 已自动切换到账号: work
   用户名: 张三（工作）
   邮箱:   zhangsan@company.com
```
