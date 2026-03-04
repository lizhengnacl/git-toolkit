# Git Toolkit - 远程脚本安装开发任务列表

## 阶段划分

- [阶段 1: 测试框架与基础设施](#阶段-1-测试框架与基础设施)
- [阶段 2: UI 显示与系统检测](#阶段-2-ui-显示与系统检测)
- [阶段 3: 用户交互与确认](#阶段-3-用户交互与确认)
- [阶段 4: 下载与安装](#阶段-4-下载与安装)
- [阶段 5: PATH 配置与启动](#阶段-5-path-配置与启动)
- [阶段 6: 集成与完整测试](#阶段-6-集成与完整测试)
- [阶段 7: 文档与验收](#阶段-7-文档与验收)

---

## 阶段 1: 测试框架与基础设施

### [P] T1.1 - 创建 install.sh 单元测试占位文件
- **文件**: `test/unit/test_install.sh`
- **描述**: 创建 install.sh 的单元测试占位文件，设置测试框架
- **前置依赖**: 无

### [P] T1.2 - 创建 install.sh 集成测试占位文件
- **文件**: `test/integration/test_install.sh`
- **描述**: 创建 install.sh 的集成测试占位文件
- **前置依赖**: 无

---

## 阶段 2: UI 显示与系统检测

### T2.1 - 编写 UI 显示函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 print_welcome_banner、print_success、print_warning、print_error、print_info 的测试
- **前置依赖**: T1.1

### T2.2 - 编写系统检测函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 detect_os_type、detect_user_shell、check_dependencies、print_install_hints 的测试
- **前置依赖**: T2.1

### T2.3 - 实现 install.sh 基础框架
- **文件**: `install.sh`
- **描述**: 创建 install.sh 文件，添加 shebang、严格模式、常量定义、cleanup 函数和 trap
- **前置依赖**: 无

### T2.4 - 实现 UI 显示函数
- **文件**: `install.sh`
- **描述**: 实现 print_welcome_banner、print_success、print_warning、print_error、print_info 函数
- **前置依赖**: T2.1, T2.3

### T2.5 - 实现系统检测函数
- **文件**: `install.sh`
- **描述**: 实现 detect_os_type、detect_user_shell、check_dependencies、print_install_hints 函数
- **前置依赖**: T2.2, T2.4

---

## 阶段 3: 用户交互与确认

### T3.1 - 编写用户交互函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 is_git_toolkit_installed、check_existing_installation、prompt_yes_no 的测试
- **前置依赖**: T1.1

### T3.2 - 实现用户交互函数
- **文件**: `install.sh`
- **描述**: 实现 is_git_toolkit_installed、check_existing_installation、prompt_yes_no 函数
- **前置依赖**: T2.5, T3.1

---

## 阶段 4: 下载与安装

### T4.1 - 编写下载与安装函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 download_repository、install_to_target_dir 的测试（Mock git 命令）
- **前置依赖**: T1.1

### T4.2 - 实现下载与安装函数
- **文件**: `install.sh`
- **描述**: 实现 download_repository（含重试机制）、install_to_target_dir（含备份）函数
- **前置依赖**: T3.2, T4.1

---

## 阶段 5: PATH 配置与启动

### T5.1 - 编写 PATH 配置函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 configure_path_if_needed、configure_path、is_path_already_configured 的测试
- **前置依赖**: T1.1

### T5.2 - 编写启动函数测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 编写 start_git_toolkit 的测试
- **前置依赖**: T5.1

### T5.3 - 实现 PATH 配置函数
- **文件**: `install.sh`
- **描述**: 实现 configure_path_if_needed、configure_path、is_path_already_configured 函数
- **前置依赖**: T4.2, T5.1

### T5.4 - 实现启动函数
- **文件**: `install.sh`
- **描述**: 实现 start_git_toolkit 函数
- **前置依赖**: T5.2, T5.3

---

## 阶段 6: 集成与完整测试

### T6.1 - 集成所有函数到 main 流程
- **文件**: `install.sh`
- **描述**: 实现 main 函数，按顺序调用所有模块函数
- **前置依赖**: T5.4

### T6.2 - 完成 install.sh 单元测试
- **文件**: `test/unit/test_install.sh`
- **描述**: 完善所有单元测试，确保覆盖所有函数和边界情况
- **前置依赖**: T6.1

### T6.3 - 实现 install.sh 集成测试
- **文件**: `test/integration/test_install.sh`
- **描述**: 编写完整的集成测试，验证完整安装流程
- **前置依赖**: T1.2, T6.2

---

## 阶段 7: 文档与验收

### T7.1 - 更新 README.md 添加安装命令
- **文件**: `README.md`
- **描述**: 在 README.md 的安装部分添加 curl 和 wget 两种安装命令
- **前置依赖**: T6.3

### T7.2 - 验证 AC1：远程脚本访问
- **文件**: 无（手工测试）
- **描述**: 测试通过 curl 和 wget 两种方式执行脚本
- **前置依赖**: T7.1

### T7.3 - 验证 AC2：系统检测与依赖检查
- **文件**: 无（手工测试）
- **描述**: 测试系统检测、依赖检查功能，验证缺失依赖时的提示
- **前置依赖**: T7.2

### T7.4 - 验证 AC3：安装流程
- **文件**: 无（手工测试）
- **描述**: 测试完整安装流程，包括已安装检测、下载重试、备份功能
- **前置依赖**: T7.3

### T7.5 - 验证 AC4：环境变量配置
- **文件**: 无（手工测试）
- **描述**: 测试 PATH 配置功能，验证标识块正确添加
- **前置依赖**: T7.4

### T7.6 - 验证 AC5：启动功能
- **文件**: 无（手工测试）
- **描述**: 测试安装后自动启动 git-toolkit 功能
- **前置依赖**: T7.5

### T7.7 - 验证 AC6：错误处理
- **文件**: 无（手工测试）
- **描述**: 测试各种错误场景，验证错误提示和清理功能
- **前置依赖**: T7.6

### T7.8 - 验证 AC7：整体质量
- **文件**: 无（手工测试）
- **描述**: 完整验收测试，验证所有验收标准，包括跨平台测试
- **前置依赖**: T7.7

---

## 任务依赖图

```
阶段 1
├── T1.1, T1.2 (并行)

阶段 2
├── T2.1 → T2.2
├── T2.3 (并行)
├── T2.1 → T2.4 → T2.5 (依赖 T2.2)

阶段 3
├── T3.1 → T3.2 (依赖 T2.5)

阶段 4
├── T4.1 → T4.2 (依赖 T3.2)

阶段 5
├── T5.1 → T5.2
├── T5.1 → T5.3 (依赖 T4.2)
├── T5.2 → T5.4 (依赖 T5.3)

阶段 6
├── T5.4 → T6.1
├── T6.1 → T6.2
├── T6.2 → T6.3 (依赖 T1.2)

阶段 7
├── T6.3 → T7.1
├── T7.1 → T7.2 → T7.3 → T7.4 → T7.5 → T7.6 → T7.7 → T7.8
```

---

## 并行执行策略

### 第一波并行（阶段 1）
- T1.1, T1.2, T2.3

### 第二波并行（阶段 2）
- T2.1, T2.2

### 第三波并行（阶段 2-3）
- T2.4, T3.1

### 第四波并行（阶段 3-4）
- T2.5, T3.2, T4.1

### 第五波并行（阶段 4-5）
- T4.2, T5.1, T5.2

### 第六波并行（阶段 5-6）
- T5.3, T5.4

### 后续按依赖顺序执行
- T6.1 → T6.2 → T6.3 → T7.1 → T7.2 → ... → T7.8

---

## 验收标准检查清单

### AC1：远程脚本访问
- [ ] 可以通过 `curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash` 执行
- [ ] 可以通过 `wget -qO- https://raw.githubusercontent.com/.../install.sh | bash` 执行
- [ ] 脚本托管在项目仓库的 install.sh 文件中

### AC2：系统检测与依赖检查
- [ ] 能正确识别 macOS 和 Linux 系统
- [ ] 检查 git 是否安装，未安装时提示
- [ ] 检查 bash 是否可用
- [ ] 检查 curl 或 wget 是否至少有一个可用
- [ ] 依赖检查失败时给出清晰的提示信息

### AC3：安装流程
- [ ] 能检测到已存在的 ~/.git-toolkit 目录
- [ ] 已安装时提示用户并询问是否覆盖
- [ ] 用户确认后能覆盖安装
- [ ] 用户拒绝时能安全退出
- [ ] 能从 GitHub 主分支下载最新代码
- [ ] 下载失败时自动重试最多 3 次
- [ ] 每次重试有间隔
- [ ] 安装过程显示进度信息
- [ ] 代码正确安装到 ~/.git-toolkit 目录

### AC4：环境变量配置
- [ ] 安装完成后询问用户是否配置环境变量
- [ ] 能正确检测用户使用的 shell（zsh 或 bash）
- [ ] 用户同意时能将 ~/.git-toolkit/bin 添加到 PATH
- [ ] 在 shell 配置文件中添加标识块
- [ ] 配置完成后提示用户重新加载 shell 配置
- [ ] 用户拒绝时不修改 shell 配置

### AC5：启动功能
- [ ] 安装成功后自动启动 git-toolkit
- [ ] 进入交互式主菜单
- [ ] 未配置环境变量时也能正常启动
- [ ] 配置环境变量后使用命令名启动

### AC6：错误处理
- [ ] 所有操作失败时有清晰的错误提示
- [ ] 下载失败超过重试次数后提示手动安装方法
- [ ] 出错时清理临时文件
- [ ] 提供合适的退出码

### AC7：整体质量
- [ ] 代码符合 constitution.md 规范
- [ ] 在 macOS 和 Linux 上正常运行
- [ ] 支持 zsh 和 bash
- [ ] 安装过程快速流畅
- [ ] 用户体验友好

---

*最后更新: 2026-03-03*
