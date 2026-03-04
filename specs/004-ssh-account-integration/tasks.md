# Git Toolkit - SSH 密钥与 Git 账号整合开发任务列表

## 阶段划分

- [阶段 1: 基础设施增强](#阶段-1-基础设施增强)
- [阶段 2: 配置工具增强](#阶段-2-配置工具增强)
- [阶段 3: SSH 模块增强](#阶段-3-ssh-模块增强)
- [阶段 4: 账号管理模块增强](#阶段-4-账号管理模块增强)
- [阶段 5: 账号向导 UI](#阶段-5-账号向导-ui)
- [阶段 6: 集成与菜单更新](#阶段-6-集成与菜单更新)
- [阶段 7: 测试与验收](#阶段-7-测试与验收)

---

## 阶段 1: 基础设施增强

### [P] T1.1 - 创建 config.sh 测试增强占位
- **文件**: `test/unit/test_config.sh`
- **描述**: 为 config.sh 新增的域名-密钥映射函数创建测试占位
- **前置依赖**: 无

### [P] T1.2 - 创建 account.sh 测试增强占位
- **文件**: `test/unit/test_account.sh`
- **描述**: 为 account.sh 增强的 load/save/edit 函数创建测试占位
- **前置依赖**: 无

### [P] T1.3 - 创建 ssh_config.sh 测试增强占位
- **文件**: `test/unit/test_ssh_config.sh`
- **描述**: 为 ssh_config.sh 增强的 add_ssh_config_for_account 和 get_key_usage 创建测试占位
- **前置依赖**: 无

### [P] T1.4 - 创建 ssh.sh 测试增强占位
- **文件**: `test/unit/test_ssh.sh`
- **描述**: 为 ssh.sh 增强的 list_ssh_keys 和新增的 get_available_ssh_keys、get_key_usage 创建测试占位
- **前置依赖**: 无

### [P] T1.5 - 创建 account_wizard.sh 测试占位
- **文件**: `test/unit/test_account_wizard.sh`
- **描述**: 为新增的 account_wizard.sh 模块创建测试占位
- **前置依赖**: 无

### [P] T1.6 - 创建集成测试增强占位
- **文件**: `test/integration/test_account.sh`
- **描述**: 为账号添加向导和编辑功能创建集成测试占位
- **前置依赖**: 无

---

## 阶段 2: 配置工具增强

### T2.1 - 实现 config.sh 域名-密钥映射函数测试
- **文件**: `test/unit/test_config.sh`
- **描述**: 编写 parse_domain_key_entry、build_domain_key_entry、extract_domains_from_config、get_key_for_domain 的完整测试
- **前置依赖**: T1.1

### [P] T2.2 - 增强 config.sh - 添加域名-密钥映射函数
- **文件**: `src/utils/config.sh`
- **描述**: 实现 parse_domain_key_entry、build_domain_key_entry、extract_domains_from_config、get_key_for_domain 函数
- **前置依赖**: T2.1

---

## 阶段 3: SSH 模块增强

### T3.1 - 实现 ssh.sh 增强测试
- **文件**: `test/unit/test_ssh.sh`
- **描述**: 为 get_available_ssh_keys、get_key_usage 和增强的 list_ssh_keys 编写完整测试
- **前置依赖**: T1.4

### T3.2 - 实现 ssh_config.sh 增强测试
- **文件**: `test/unit/test_ssh_config.sh`
- **描述**: 为增强的 add_ssh_config_for_account 和新增的 get_key_usage 编写完整测试
- **前置依赖**: T1.3

### [P] T3.3 - 增强 ssh.sh - 添加密钥使用情况显示
- **文件**: `src/core/ssh.sh`
- **描述**: 实现 get_available_ssh_keys、get_key_usage 函数，增强 list_ssh_keys 显示使用情况
- **前置依赖**: T3.1

### [P] T3.4 - 增强 ssh_config.sh - 支持域名-密钥映射
- **文件**: `src/utils/ssh_config.sh`
- **描述**: 增强 add_ssh_config_for_account 支持域名-密钥映射，实现 get_key_usage 函数
- **前置依赖**: T2.2, T3.2

---

## 阶段 4: 账号管理模块增强

### T4.1 - 实现 account.sh 增强测试
- **文件**: `test/unit/test_account.sh`
- **描述**: 为增强的 load_account_config、save_account_config、list_accounts 和新增的 edit_account 编写完整测试
- **前置依赖**: T1.2

### T4.2 - 增强 account.sh - 支持新旧格式兼容
- **文件**: `src/core/account.sh`
- **描述**: 增强 load_account_config 和 save_account_config 函数，支持新旧配置格式兼容，支持 DOMAIN_SSH_KEYS
- **前置依赖**: T2.2, T4.1

### T4.3 - 增强 account.sh - 添加编辑功能
- **文件**: `src/core/account.sh`
- **描述**: 实现 edit_account 函数，包含变更预览功能
- **前置依赖**: T4.2

### T4.4 - 增强 account.sh - 更新显示功能
- **文件**: `src/core/account.sh`
- **描述**: 更新 list_accounts 显示默认密钥和域名-密钥映射
- **前置依赖**: T4.3

---

## 阶段 5: 账号向导 UI

### T5.1 - 实现 account_wizard.sh 测试
- **文件**: `test/unit/test_account_wizard.sh`
- **描述**: 为 run_account_add_wizard、prompt_ssh_key_option、prompt_generate_ssh_key、prompt_select_ssh_key、prompt_domains、prompt_domain_key_mapping 编写完整测试
- **前置依赖**: T1.5

### T5.2 - 创建 account_wizard.sh - SSH 密钥选项提示
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 prompt_ssh_key_option 函数
- **前置依赖**: T5.1

### T5.3 - 创建 account_wizard.sh - 生成新密钥提示
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 prompt_generate_ssh_key 函数
- **前置依赖**: T5.2

### T5.4 - 创建 account_wizard.sh - 选择已有密钥提示
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 prompt_select_ssh_key 函数
- **前置依赖**: T3.3, T5.3

### T5.5 - 创建 account_wizard.sh - 域名提示
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 prompt_domains 函数
- **前置依赖**: T5.4

### T5.6 - 创建 account_wizard.sh - 域名-密钥映射提示
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 prompt_domain_key_mapping 函数
- **前置依赖**: T3.3, T5.5

### T5.7 - 创建 account_wizard.sh - 主向导流程
- **文件**: `src/ui/account_wizard.sh`
- **描述**: 实现 run_account_add_wizard 函数，整合所有提示函数
- **前置依赖**: T5.6, T4.4, T3.4

---

## 阶段 6: 集成与菜单更新

### T6.1 - 更新 menu.sh - 添加账号编辑选项
- **文件**: `src/ui/menu.sh`
- **描述**: 在账号管理菜单中新增"编辑 Git 账号"选项
- **前置依赖**: T4.4

### T6.2 - 更新 menu.sh - 添加 SSH 密钥管理选项
- **文件**: `src/ui/menu.sh`
- **描述**: 在账号管理菜单中新增"管理 SSH 密钥"选项
- **前置依赖**: T6.1, T3.3

### T6.3 - 更新 menu.sh - 集成账号添加向导
- **文件**: `src/ui/menu.sh`
- **描述**: 更新"添加 Git 账号"选项，使用 account_wizard.sh
- **前置依赖**: T5.7, T6.2

### T6.4 - 更新 bin/git-toolkit - 集成新功能
- **文件**: `bin/git-toolkit`
- **描述**: 更新主入口，集成新增的编辑账号和账号向导功能
- **前置依赖**: T6.3

---

## 阶段 7: 测试与验收

### T7.1 - 实现集成测试
- **文件**: `test/integration/test_account.sh`
- **描述**: 编写账号添加向导和编辑功能的完整集成测试
- **前置依赖**: T1.6, T6.4

### T7.2 - 验证 AC1：账号添加流程整合
- **文件**: 无（手工测试）
- **描述**: 手工测试账号添加向导的完整流程，验证所有选项（生成新密钥、选择已有密钥、跳过）
- **前置依赖**: T6.4

### T7.3 - 验证 AC2：按域名关联不同 SSH 密钥
- **文件**: 无（手工测试）
- **描述**: 手工测试为不同域名配置不同密钥的功能，验证 SSH config 生成
- **前置依赖**: T7.2

### T7.4 - 验证 AC3：SSH 密钥管理增强
- **文件**: 无（手工测试）
- **描述**: 手工测试查看账号关联密钥、显示密钥使用情况功能
- **前置依赖**: T7.3

### T7.5 - 验证 AC4：配置文件兼容
- **文件**: 无（手工测试）
- **描述**: 手工测试新旧配置格式的兼容性，手动编辑配置文件后验证工具仍能正常工作
- **前置依赖**: T7.4

### T7.6 - 验证 AC5：账号编辑功能
- **文件**: 无（手工测试）
- **描述**: 手工测试编辑账号功能，验证各项修改和变更预览
- **前置依赖**: T7.5

### T7.7 - 验证 AC6：整体质量
- **文件**: 无（手工测试）
- **描述**: 完整验收测试，验证所有验收标准
- **前置依赖**: T7.6

---

## 任务依赖图

```
阶段 1
├── T1.1, T1.2, T1.3, T1.4, T1.5, T1.6 (并行)

阶段 2
├── T2.1 → T2.2

阶段 3
├── T3.1 → T3.3
├── T3.2 → T3.4 (依赖 T2.2)

阶段 4
├── T4.1 → T4.2 (依赖 T2.2) → T4.3 → T4.4

阶段 5
├── T5.1 → T5.2 → T5.3 → T5.4 (依赖 T3.3) → T5.5 → T5.6 (依赖 T3.3) → T5.7 (依赖 T4.4, T3.4)

阶段 6
├── T4.4 → T6.1 → T6.2 (依赖 T3.3) → T6.3 (依赖 T5.7) → T6.4

阶段 7
├── T1.6, T6.4 → T7.1
├── T6.4 → T7.2 → T7.3 → T7.4 → T7.5 → T7.6 → T7.7
```

---

## 并行执行策略

### 第一波并行（阶段 1）
- T1.1, T1.2, T1.3, T1.4, T1.5, T1.6

### 第二波并行（阶段 1-2）
- T2.1, T3.1, T3.2, T4.1, T5.1

### 第三波并行（阶段 2-3）
- T2.2, T3.3, T3.4

### 第四波并行（阶段 3-4）
- T4.2, T5.2, T5.3

### 第五波并行（阶段 4-5）
- T4.3, T5.4, T5.5

### 第六波并行（阶段 4-5）
- T4.4, T5.6

### 后续按依赖顺序执行
- T5.7 → T6.1 → T6.2 → T6.3 → T6.4 → T7.1 → T7.2 → ... → T7.7

---

## 验收标准检查清单

### AC1：账号添加流程整合
- [ ] 添加账号时提供统一的交互流程
- [ ] 可以选择生成新的 SSH 密钥
- [ ] 可以选择已有的 SSH 密钥
- [ ] 可以选择暂不配置 SSH 密钥
- [ ] 生成新密钥时支持自定义名称和注释
- [ ] 选择已有密钥时正确列出可用密钥

### AC2：按域名关联不同 SSH 密钥
- [ ] 账号配置支持为每个域名指定密钥
- [ ] 未指定密钥的域名使用账号默认密钥
- [ ] SSH config 正确生成域名-密钥映射
- [ ] 编辑账号时可以修改域名与密钥的关联

### AC3：SSH 密钥管理增强
- [ ] 可以查看账号关联的所有 SSH 密钥
- [ ] 可以为已有账号添加/更换 SSH 密钥
- [ ] 可以解除账号与 SSH 密钥的关联
- [ ] 列出 SSH 密钥时显示使用情况

### AC4：配置文件兼容
- [ ] 现有配置文件无需修改即可正常工作
- [ ] 支持新的配置格式（域名-密钥映射）
- [ ] 自动识别和兼容新旧两种格式
- [ ] 手动编辑配置文件后工具仍能正常工作

### AC5：账号编辑功能
- [ ] 可以编辑 Git 信息（用户名、邮箱）
- [ ] 可以编辑 SSH 密钥配置
- [ ] 可以编辑域名列表及对应密钥
- [ ] 编辑时提供变更预览

### AC6：整体质量
- [ ] 代码符合 constitution.md 规范
- [ ] 所有功能有清晰的错误处理
- [ ] 在 macOS 和 Linux 上正常运行
- [ ] 配置文件格式易于手动编辑
- [ ] 操作响应及时，不影响用户体验

---

*最后更新: 2026-03-04*
