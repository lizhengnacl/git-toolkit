# Git Toolkit - 自动账号切换开发任务列表

## 阶段划分

- [阶段 1: 基础设施增强](#阶段-1-基础设施增强)
- [阶段 2: SSH 配置管理](#阶段-2-ssh-配置管理)
- [阶段 3: 自动切换核心逻辑](#阶段-3-自动切换核心逻辑)
- [阶段 4: cd 钩子管理](#阶段-4-cd-钩子管理)
- [阶段 5: 集成与菜单更新](#阶段-5-集成与菜单更新)
- [阶段 6: 测试与验收](#阶段-6-测试与验收)

---

## 阶段 1: 基础设施增强

### [P] T1.1 - 创建 ssh_config 模块单元测试
- **文件**: `test/unit/test_ssh_config.sh`
- **描述**: 创建 SSH config 管理模块的单元测试占位文件
- **前置依赖**: 无

### [P] T1.2 - 创建 auto_switch 模块单元测试
- **文件**: `test/unit/test_auto_switch.sh`
- **描述**: 创建自动切换模块的单元测试占位文件
- **前置依赖**: 无

### [P] T1.3 - 创建 auto_switch 集成测试
- **文件**: `test/integration/test_auto_switch.sh`
- **描述**: 创建自动切换功能的集成测试占位文件
- **前置依赖**: 无

### T1.4 - 实现 validation.sh 测试增强（通配符域名）
- **文件**: `test/unit/test_validation.sh`
- **描述**: 为 validate_domain 函数添加通配符支持的测试
- **前置依赖**: 无

### T1.5 - 实现 git.sh 测试增强
- **文件**: `test/unit/test_git.sh`
- **描述**: 为 git_get_first_remote、git_get_remote_url、git_is_repository 添加测试
- **前置依赖**: 无

### [P] T1.6 - 更新 constants.sh - 添加新常量
- **文件**: `src/constants.sh`
- **描述**: 添加 SSH_CONFIG_FILE、SSH_CONFIG_START_MARKER、SSH_CONFIG_END_MARKER、CD_HOOK_START_MARKER、CD_HOOK_END_MARKER
- **前置依赖**: 无

### [P] T1.7 - 增强 validation.sh - 支持通配符域名
- **文件**: `src/utils/validation.sh`
- **描述**: 更新 validate_domain 函数，支持 *.example.com 和 git.* 格式的通配符
- **前置依赖**: T1.4

### [P] T1.8 - 增强 git.sh - 添加新函数
- **文件**: `src/utils/git.sh`
- **描述**: 添加 git_get_first_remote、git_get_remote_url、git_is_repository 函数
- **前置依赖**: T1.5

### [P] T1.9 - 增强 config.sh - 添加配置加载函数
- **文件**: `src/utils/config.sh`
- **描述**: 添加 load_all_accounts、build_domain_account_map 函数
- **前置依赖**: 无

---

## 阶段 2: SSH 配置管理

### T2.1 - 实现 ssh_config.sh 完整测试
- **文件**: `test/unit/test_ssh_config.sh`
- **描述**: 编写 add_ssh_config、remove_ssh_config、add_ssh_config_for_account、remove_ssh_config_for_account、list_managed_ssh_config、rebuild_all_ssh_config 的完整测试
- **前置依赖**: T1.1

### T2.2 - 创建 src/utils/ssh_config.sh
- **文件**: `src/utils/ssh_config.sh`
- **描述**: 实现 SSH config 管理模块的所有函数
- **前置依赖**: T1.6, T2.1

---

## 阶段 3: 自动切换核心逻辑

### T3.1 - 实现 auto_switch.sh 完整测试
- **文件**: `test/unit/test_auto_switch.sh`
- **描述**: 编写 auto_switch_account、extract_domain_from_url、match_account_by_domain、match_wildcard_domain 的完整测试
- **前置依赖**: T1.2

### T3.2 - 创建 src/core/auto_switch.sh
- **文件**: `src/core/auto_switch.sh`
- **描述**: 实现自动切换模块的所有函数
- **前置依赖**: T1.6, T1.7, T1.8, T1.9, T3.1

---

## 阶段 4: cd 钩子管理

### T4.1 - 实现 cd 钩子管理测试
- **文件**: `test/unit/test_auto_switch.sh`
- **描述**: 编写 install_cd_hook、uninstall_cd_hook、is_cd_hook_installed 的完整测试
- **前置依赖**: T3.1

### T4.2 - 增强 auto_switch.sh - 添加 cd 钩子函数
- **文件**: `src/core/auto_switch.sh`
- **描述**: 添加 install_cd_hook、uninstall_cd_hook、is_cd_hook_installed 函数
- **前置依赖**: T3.2, T4.1

---

## 阶段 5: 集成与菜单更新

### T5.1 - 增强 account.sh - 集成 SSH 配置管理
- **文件**: `src/core/account.sh`
- **描述**: 更新 add_account、delete_account、list_accounts 函数，集成 SSH 配置管理
- **前置依赖**: T2.2

### T5.2 - 更新 menu.sh - 新增菜单选项
- **文件**: `src/ui/menu.sh`
- **描述**: 在账号管理菜单中新增"安装/管理 cd 钩子"和"查看 SSH 配置"选项
- **前置依赖**: T5.1

### T5.3 - 更新 bin/git-toolkit - 新增子命令
- **文件**: `bin/git-toolkit`
- **描述**: 在 account 子命令中新增 auto-switch 和 hook 子命令处理
- **前置依赖**: T4.2, T5.2

---

## 阶段 6: 测试与验收

### T6.1 - 实现 auto_switch 集成测试
- **文件**: `test/integration/test_auto_switch.sh`
- **描述**: 编写完整的自动切换功能集成测试
- **前置依赖**: T1.3, T5.3

### T6.2 - 验证 AC1：cd 钩子安装与管理
- **文件**: 无（手工测试）
- **描述**: 手工测试 cd 钩子的安装、查看状态、卸载功能
- **前置依赖**: T5.3

### T6.3 - 验证 AC2：基于 remote URL 的自动切换
- **文件**: 无（手工测试）
- **描述**: 手工测试进入仓库时的自动切换功能
- **前置依赖**: T6.2

### T6.4 - 验证 AC3：通配符域名匹配
- **文件**: 无（手工测试）
- **描述**: 手工测试通配符域名匹配功能
- **前置依赖**: T6.3

### T6.5 - 验证 AC4：SSH 配置自动管理
- **文件**: 无（手工测试）
- **描述**: 手工测试 SSH 配置的自动添加、更新、删除功能
- **前置依赖**: T6.4

### T6.6 - 验证 AC5：账号配置管理增强
- **文件**: 无（手工测试）
- **描述**: 手工测试添加账号时的域名输入、列表显示功能
- **前置依赖**: T6.5

### T6.7 - 验证 AC6：整体质量
- **文件**: 无（手工测试）
- **描述**: 完整验收测试，验证所有验收标准
- **前置依赖**: T6.6

---

## 任务依赖图

```
阶段 1
├── T1.1, T1.2, T1.3, T1.6 (并行)
├── T1.4 → T1.7
├── T1.5 → T1.8
├── T1.9 (并行)

阶段 2
├── T2.1 → T2.2 (依赖 T1.6)

阶段 3
├── T3.1 → T3.2 (依赖 T1.6, T1.7, T1.8, T1.9)

阶段 4
├── T4.1 → T4.2 (依赖 T3.2)

阶段 5
├── T2.2 → T5.1 → T5.2 → T5.3
├── T4.2 → T5.3

阶段 6
├── T1.3, T5.3 → T6.1
├── T5.3 → T6.2 → T6.3 → T6.4 → T6.5 → T6.6 → T6.7
```

---

## 并行执行策略

### 第一波并行（阶段 1）
- T1.1, T1.2, T1.3, T1.4, T1.5, T1.6, T1.9

### 第二波并行（阶段 1-2）
- T1.7, T1.8, T2.1

### 第三波并行（阶段 2-3）
- T2.2, T3.1

### 第四波并行（阶段 3-4）
- T3.2, T4.1

### 第五波并行（阶段 4-5）
- T4.2, T5.1

### 后续按依赖顺序执行
- T5.2 → T5.3 → T6.1 → T6.2 → ... → T6.7

---

## 验收标准检查清单

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

*最后更新: 2026-03-03*
