# Quietly · Copilot 开发指引（项目特有）

## 先读门禁（强制）
本仓库的强约束以根目录 [AI_INSTRUCTIONS.md](../../AI_INSTRUCTIONS.md) 为权威源；`.github/` 下的同步副本是 [.github/AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md)。

补充约束见 [CONSTRAINTS.md](../../CONSTRAINTS.md)。

在没有人类明确回复“批准实现”之前：
- 不要修改/新增文件
- 不要输出代码、patch 或命令
- 只产出文档（按 templates 模板）

## 项目概览
Quietly 是一个 **macOS 菜单栏情境自动化工具**：通过轮询采集系统状态（如合盖、电源、外接显示器、蓝牙等），用“前后状态 diff”触发规则，再执行动作。

目标架构与关键设计理由见：
- [docs/TECH_SPEC_V2.md](../../docs/TECH_SPEC_V2.md)

## 当前代码形态（可发现事实）
- [Quietly/QuietlyApp.swift](../../Quietly/QuietlyApp.swift)：当前是 SwiftUI `@main` 入口（基础模板）。
- [Quietly/ContentView.swift](../../Quietly/ContentView.swift)：当前为占位 UI（"Hello, world!"）。

当前代码以 SwiftUI 模板为主；如需引入后台轮询/规则引擎等结构，请保持“最小增量变更”，并严格遵守“无数据库”等强约束。

## 关键约定（从设计稿可验证）
- **State-driven**：以“轮询 + 状态差分”作为事实来源；规则只在边缘变化触发（例如 `!prev.lidClosed && curr.lidClosed`）。
- **性能约束**：单次轮询应快速返回（设计稿要求 < 50ms），避免在主线程做阻塞工作。
- **无数据库**：Phase 1–2 不使用 SwiftData/CoreData/SQLite；配置建议使用 `UserDefaults`（见设计稿）。

## 常见变更落点（建议按此找文件/建文件）
- 系统状态采集、轮询、diff、规则评估：优先对齐 [docs/TECH_SPEC_V2.md](../../docs/TECH_SPEC_V2.md)
- 测试：现有测试目标在 [QuietlyTests/QuietlyTests.swift](../../QuietlyTests/QuietlyTests.swift) 与 [QuietlyUITests/](../../QuietlyUITests/)

## 外部集成提示（仅基于设计稿）
- 合盖状态：`ioreg -r -k AppleClamshellState`
- 蓝牙开关：`blueutil --power`

如需引入新依赖或改变生命周期/架构边界，先按流程在阶段 1/2 写入方案与风险并等待批准。
