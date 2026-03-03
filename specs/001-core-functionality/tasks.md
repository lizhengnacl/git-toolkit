# Git Toolkit 开发任务列表

## 阶段划分

- [阶段 1: 基础设施](#阶段-1-基础设施)
- [阶段 2: 初始化功能](#阶段-2-初始化功能)
- [阶段 3: SSH 功能](#阶段-3-ssh-功能)
- [阶段 4: 账号和 Alias 管理](#阶段-4-账号和-alias-管理)

---

## 阶段 1: 基础设施

### [P] T1.1 - 创建测试框架占位文件
- **文件**: `test/unit/test_logger.sh`
- **描述**: 创建 logger 模块的单元测试占位文件
- **前置依赖**: 无

### [P] T1.2 - 创建测试框架占位文件
- **文件**: `test/unit/test_validation.sh`
- **描述**: 创建 validation 模块的单元测试占位文件
- **前置依赖**: 无

### [P] T1.3 - 创建测试框架占位文件
- **文件**: `test/unit/test_git.sh`
- **描述**: 创建 git 模块的单元测试占位文件
- **前置依赖**: 无

### T1.4 - 实现 validation.sh 测试
- **文件**: `test/unit/test_validation.sh`
- **描述**: 编写 validate_email、validate_username、validate_domain、validate_path 的完整测试
- **前置依赖**: T1.2

### T1.5 - 实现 git.sh 测试
- **文件**: `test/unit/test_git.sh`
- **描述**: 编写 git_set_config、git_get_config、git_unset_config、git_has_config 的完整测试
- **前置依赖**: T1.3

### [P] T1.6 - 创建 src/utils/validation.sh
- **文件**: `src/utils/validation.sh`
- **描述**: 实现输入验证函数（validate_email、validate_username、validate_domain、validate_path）
- **前置依赖**: T1.4

### [P] T1.7 - 创建 src/utils/git.sh
- **文件**: `src/utils/git.sh`
- **描述**: 实现 Git 配置操作封装（git_set_config、git_get_config、git_unset_config、git_has_config）
- **前置依赖**: T1.5

### [P] T1.8 - 创建 src/utils/config.sh
- **文件**: `src/utils/config.sh`
- **描述**: 实现配置文件读写函数（load_account_config、save_account_config、load_alias_config、save_alias_config）
- **前置依赖**: 无

### [P] T1.9 - 创建 src/utils/backup.sh
- **文件**: `src/utils/backup.sh`
- **描述**: 实现备份工具函数（create_backup、list_backups、restore_backup）
- **前置依赖**: 无

---

## 阶段 2: 初始化功能

### T2.1 - 创建 init 模块集成测试
- **文件**: `test/integration/test_init.sh`
- **描述**: 编写初始化功能的集成测试
- **前置依赖**: 无

### [P] T2.2 - 创建 src/ui/prompt.sh
- **文件**: `src/ui/prompt.sh`
- **描述**: 实现用户输入处理函数（prompt_text、prompt_yes_no、prompt_choice、prompt_password）
- **前置依赖**: 无

### [P] T2.3 - 创建 src/ui/menu.sh
- **文件**: `src/ui/menu.sh`
- **描述**: 实现交互式菜单函数（show_main_menu、show_init_menu 等）
- **前置依赖**: T2.2

### T2.4 - 创建 src/core/init.sh
- **文件**: `src/core/init.sh`
- **描述**: 实现初始化功能（init_git_environment、configure_git_settings、apply_default_aliases）
- **前置依赖**: T1.6, T1.7, T1.9, T2.2

### T2.5 - 创建 bin/git-toolkit 主入口
- **文件**: `bin/git-toolkit`
- **描述**: 实现主入口脚本，解析命令行参数，调用对应功能
- **前置依赖**: T2.3, T2.4
- **后处理**: 执行 `chmod +x bin/git-toolkit`

### T2.6 - 验证初始化功能
- **文件**: 无（手工测试）
- **描述**: 手工测试初始化功能，验证 AC1 验收标准
- **前置依赖**: T2.5

---

## 阶段 3: SSH 功能

### T3.1 - 创建 SSH 模块集成测试
- **文件**: `test/integration/test_ssh.sh`
- **描述**: 编写 SSH 功能的集成测试
- **前置依赖**: 无

### T3.2 - 创建 src/core/ssh.sh
- **文件**: `src/core/ssh.sh`
- **描述**: 实现 SSH 密钥管理功能（generate_ssh_key、copy_public_key、test_ssh_connection）
- **前置依赖**: T1.6, T1.8

### T3.3 - 更新 src/ui/menu.sh - 添加 SSH 菜单
- **文件**: `src/ui/menu.sh`
- **描述**: 添加 SSH 相关子菜单（show_ssh_menu）
- **前置依赖**: T2.3, T3.2

### T3.4 - 更新 bin/git-toolkit - 添加 ssh 命令
- **文件**: `bin/git-toolkit`
- **描述**: 添加 ssh 子命令处理
- **前置依赖**: T2.5, T3.3

### T3.5 - 验证 SSH 功能
- **文件**: 无（手工测试）
- **描述**: 手工测试 SSH 功能，验证 AC2 验收标准
- **前置依赖**: T3.4

---

## 阶段 4: 账号和 Alias 管理

### T4.1 - 创建账号管理模块集成测试
- **文件**: `test/integration/test_account.sh`
- **描述**: 编写账号管理功能的集成测试
- **前置依赖**: 无

### T4.2 - 创建 Alias 管理模块集成测试
- **文件**: `test/integration/test_alias.sh`
- **描述**: 编写 Alias 管理功能的集成测试
- **前置依赖**: 无

### [P] T4.3 - 创建 src/core/account.sh
- **文件**: `src/core/account.sh`
- **描述**: 实现多账号管理功能（add_account、list_accounts、switch_account、delete_account、get_current_account）
- **前置依赖**: T1.6, T1.7, T1.8, T4.1

### [P] T4.4 - 创建 src/core/alias.sh
- **文件**: `src/core/alias.sh`
- **描述**: 实现 Alias 管理功能（apply_preset_aliases、add_alias、remove_alias、list_aliases）
- **前置依赖**: T1.7, T1.8, T4.2

### T4.5 - 更新 src/ui/menu.sh - 添加账号菜单
- **文件**: `src/ui/menu.sh`
- **描述**: 添加账号管理子菜单（show_account_menu）
- **前置依赖**: T3.3, T4.3

### T4.6 - 更新 src/ui/menu.sh - 添加 Alias 菜单
- **文件**: `src/ui/menu.sh`
- **描述**: 添加 Alias 管理子菜单（show_alias_menu）
- **前置依赖**: T4.5, T4.4

### T4.7 - 更新 bin/git-toolkit - 添加 account 命令
- **文件**: `bin/git-toolkit`
- **描述**: 添加 account 子命令处理
- **前置依赖**: T3.4, T4.5

### T4.8 - 更新 bin/git-toolkit - 添加 alias 命令
- **文件**: `bin/git-toolkit`
- **描述**: 添加 alias 子命令处理
- **前置依赖**: T4.7, T4.6

### T4.9 - 验证账号管理功能
- **文件**: 无（手工测试）
- **描述**: 手工测试账号管理功能，验证 AC3 验收标准
- **前置依赖**: T4.8

### T4.10 - 验证 Alias 管理功能
- **文件**: 无（手工测试）
- **描述**: 手工测试 Alias 管理功能，验证 AC4 验收标准
- **前置依赖**: T4.9

### T4.11 - 整体质量验证
- **文件**: 无（手工测试）
- **描述**: 完整验收测试，验证 AC5 验收标准
- **前置依赖**: T4.10

---

## 任务依赖图

```
阶段 1
├── T1.1, T1.2, T1.3 (并行)
├── T1.4 → T1.6
├── T1.5 → T1.7
├── T1.8, T1.9 (并行)

阶段 2
├── T2.1
├── T2.2 → T2.3 → T2.5
├── T2.4 (依赖 T1.6, T1.7, T1.9, T2.2) → T2.5
├── T2.5 → T2.6

阶段 3
├── T3.1
├── T3.2 (依赖 T1.6, T1.8) → T3.3 → T3.4 → T3.5

阶段 4
├── T4.1 → T4.3 → T4.5 → T4.7 → T4.9
├── T4.2 → T4.4 → T4.6 → T4.8 → T4.10
├── T4.9, T4.10 → T4.11
```

---

## 并行执行策略

### 第一波并行（阶段 1）
- T1.1, T1.2, T1.3, T1.8, T1.9

### 第二波并行（阶段 1）
- T1.4, T1.5

### 第三波并行（阶段 1-2）
- T1.6, T1.7, T2.1, T2.2

### 第四波并行（阶段 2-3）
- T2.3, T2.4, T3.1, T4.1, T4.2

### 第五波并行（阶段 3-4）
- T3.2, T4.3, T4.4

### 后续按依赖顺序执行

---

## 验收标准检查清单

### AC1: 初始化功能
- [ ] 运行工具后显示交互式菜单
- [ ] 选择初始化选项后，引导输入用户名和邮箱
- [ ] 确认后应用配置到 Git 全局配置
- [ ] 原有配置被备份
- [ ] 预设的 alias 被正确配置

### AC2: SSH 密钥生成
- [ ] 可以选择生成 Ed25519 密钥
- [ ] 可以自定义密钥文件名
- [ ] 公钥内容被显示并提示如何添加到平台
- [ ] 提供测试 SSH 连接的选项

### AC3: 多账号管理
- [ ] 可以添加新账号配置
- [ ] 可以查看已配置的账号列表
- [ ] 可以手动切换全局账号
- [ ] 配置文件正确存储在 ~/.git-toolkit/accounts/
- [ ] 按域名切换功能正常工作

### AC4: Alias 管理
- [ ] 预设的基础和进阶 alias 可用
- [ ] 可以添加自定义 alias
- [ ] 可以删除 alias
- [ ] 配置变更立即生效

### AC5: 整体质量
- [ ] 代码符合 constitution.md 规范
- [ ] 所有功能有清晰的错误处理
- [ ] 在 macOS 和 Linux 上正常运行
- [ ] 配置文件格式易于手动编辑

---

*最后更新: 2026-03-03*
