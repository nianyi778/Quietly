# Quietly · Technical Design Spec v2

**macOS Menu Bar Context Automation Tool**

> Version: v2 (No-DB, Performance-first)
> Target: macOS 13+ (Apple Silicon 优先)
> Distribution: Independent (Developer ID + Notarization)

---

## 1. Design Goals（设计目标）

### 1.1 核心目标

* 常驻菜单栏、低功耗、低占用
* 状态驱动（State-driven），而非事件驱动
* 行为可预测、可逆、可去重
* 不依赖数据库（Phase 1–2）
* 架构可演进（Phase 3 可加复杂规则）

### 1.2 明确不做的事（v2）

* 不使用 SwiftData / CoreData / SQLite
* 不使用 sleep/wake/lid event 监听
* 不提供自由工作流编辑
* 不引入云同步 / CloudKit

---

## 2. Overall Architecture（总体架构）

```
┌────────────────────────────────────┐
│           AppKit Shell              │
│  (NSApplication / AppDelegate)      │
│                                    │
│   ┌──────────────┐                 │
│   │ Status Bar UI│  SwiftUI View   │
│   └──────────────┘                 │
│            │                       │
│            ▼                       │
│     AutomationEngine               │  ← 核心中枢
│   ┌──────────────────────────┐    │
│   │  StateMonitor (Polling)   │    │
│   │  RuleEngine (Diff-based)  │    │
│   │  ActionExecutor           │    │
│   │  NotificationManager      │    │
│   │  Logger (in-memory)       │    │
│   └──────────────────────────┘    │
│            │                       │
│            ▼                       │
│     Persistence Layer              │
│   (UserDefaults + JSON optional)   │
└────────────────────────────────────┘
```

---

## 3. App Lifecycle & Runtime Model

### 3.1 App Lifecycle

* AppKit 管理生命周期（非 SwiftUI App lifecycle）
* App 启动即：

  1. 初始化 AutomationEngine
  2. 加载规则配置（UserDefaults）
  3. 启动 StateMonitor 定时轮询
  4. 创建菜单栏 UI

### 3.2 Runtime Characteristics

* 无 Dock icon（LSUIElement = YES）
* 无主窗口
* UI 仅作为状态展示与控制面板
* 后台逻辑与 UI 解耦

---

## 4. State-driven Engine（核心引擎）

### 4.1 为什么是 State-driven

* macOS Clamshell 模式下：

  * lid / sleep / wake 事件不可靠
* 系统“状态”始终可信
* 使用 **轮询 + 状态差分（diff）** 是最稳方案

---

## 5. System State Model（系统状态模型）

```pseudo
struct SystemState {
  timestamp: Int64

  // Hardware / Power
  lidClosed: Bool
  onBattery: Bool
  externalDisplayConnected: Bool

  // Connectivity
  bluetoothEnabled: Bool

  // Optional (future)
  activeWifiSSID: String?
  focusModeEnabled: Bool?
}
```

### 状态采集方式（v2 推荐）

| State            | Method                            |
| ---------------- | --------------------------------- |
| lidClosed        | `ioreg -r -k AppleClamshellState` |
| onBattery        | IOKit Power Source                |
| externalDisplay  | CoreGraphics                      |
| bluetoothEnabled | `blueutil --power`                |

---

## 6. StateMonitor（状态监控器）

### 6.1 Polling Strategy

* 默认轮询间隔：**5 秒**
* 后台定时器（非主线程）
* 单次轮询必须 < 50ms

### 6.2 State Collection Pseudocode

```pseudo
function collectState(): SystemState {
  return SystemState(
    timestamp = now(),
    lidClosed = readClamshellState(),
    onBattery = readPowerState(),
    externalDisplayConnected = readDisplays(),
    bluetoothEnabled = readBluetooth()
  )
}
```

---

## 7. Rule Engine（规则引擎 v2）

### 7.1 Rule Design（Phase 1）

> **规则 = 状态变化触发的单一行为**

```pseudo
enum RuleID {
  LidClose_BluetoothOff
  LidOpen_BluetoothOn
  OnBattery_PowerSave
  ExternalDisplay_AudioSwitch
  Night_FocusMode
}

struct RuleConfig {
  id: RuleID
  enabled: Bool
}
```

---

### 7.2 Diff-based Evaluation（关键）

```pseudo
function evaluate(prev, curr, enabledRules):
  actions = []

  if ruleEnabled(LidClose_BluetoothOff):
    if !prev.lidClosed && curr.lidClosed:
      actions.append(SetBluetooth(false))

  if ruleEnabled(LidOpen_BluetoothOn):
    if prev.lidClosed && !curr.lidClosed:
      actions.append(SetBluetooth(true))

  if ruleEnabled(OnBattery_PowerSave):
    if !prev.onBattery && curr.onBattery:
      actions.append(SetBluetooth(false))

  return actions
```

### 7.3 去重 & 幂等原则

* **只在状态“边沿变化”时触发**
* Action 执行前检查当前状态
* 状态已满足 → skip（不执行、不通知）

---

## 8. Action Executor（动作执行器）
 
### 8.1 Action Model

```pseudo
enum Action {
  SetBluetooth(on: Bool)
  SwitchAudioOutput(device: String)
  EnableFocusMode(on: Bool)
}
```

### 8.2 执行流程

```pseudo
function execute(action, currentState):
  if action already satisfied:
    return SKIPPED

  run system command / API
  if success:
    return SUCCESS
  else:
    return FAILED
```

### 8.3 蓝牙控制（Phase 1 推荐）

* 使用 `blueutil`
* 优点：稳定、低权限、可预测

---

## 9. Persistence Strategy（无数据库方案）

### 9.1 持久化分层

| 层级     | 技术             | 用途              |
| ------ | -------------- | --------------- |
| 配置     | UserDefaults   | 规则启用、全局暂停       |
| 状态     | 内存             | 上一次 SystemState |
| 日志     | 内存 Ring Buffer | 最近一次动作          |
| 文件（可选） | JSON           | 诊断 / 导出         |

### 9.2 Rule Store 抽象（为未来扩展）

```pseudo
protocol RuleStore {
  func loadConfigs() -> [RuleConfig]
  func saveConfigs(_ configs)
}
```

* v2 实现：`UserDefaultsRuleStore`
* v3 可替换：`SQLiteRuleStore`（无需改 RuleEngine）

---

## 10. Menu Bar UI（交互实现）

### 10.1 UI 职责

* 展示规则列表（checkbox）
* 展示最近一次动作
* 提供全局暂停
* 打开设置页

### 10.2 UI → Engine 通信

* UI 修改 RuleConfig
* Engine 监听配置变化（Observable / Publisher）

---

## 11. Notification Strategy

* 使用 `UNUserNotificationCenter`
* 仅在 **Action SUCCESS / FAILED** 时通知
* SKIPPED 不通知
* 可在 Settings 中关闭

---

## 12. Performance & Resource Budget

### 12.1 性能目标

* CPU：长期 < 0.5%
* 内存：< 50MB
* 电量影响：可忽略

### 12.2 为什么可达成

* 低频轮询
* 无数据库
* 无常驻线程阻塞
* 无 UI 动画

---

## 13. Error Handling & Fallback

### 13.1 State Read Failure

* 保留上一状态
* 不触发规则
* 记录日志

### 13.2 Action Failure

* 记录失败
* Toast 提示一次
* 不立即重试（等待下次状态变化）

---

## 14. Build & Distribution

### 14.1 App Configuration

* `LSUIElement = YES`
* 无 Dock icon
* 菜单栏常驻

### 14.2 Signing & Notarization

* Developer ID Application
* `codesign` + `notarytool`
* DMG 分发

---

## 15. Phase Evolution（不推翻架构）

### Phase 2

* Rule Detail View
* 条件开关（电池 / 显示器）
* 多 Action 顺序执行（线性）

### Phase 3

* 受限工作流（非自由 DAG）
* 高级用户脚本 Action
* 可选数据库（仅当规则爆炸）

---

## 16. Definition of Done（v2）

* Clamshell 合盖 → 蓝牙 5 秒内关闭
* 开盖 → 蓝牙恢复
* 不重复触发
* 菜单栏 UI 状态清晰
* 无数据库、无迁移成本
* 长期运行稳定

---

## 17. Summary（一句话）

> Quietly v2 是一个 **以“状态”为核心、以“稳定”为第一原则** 的 macOS 自动化引擎，而不是一个配置系统。

---

### ✅ 你现在可以直接做什么

你现在可以把这份 `TECH_SPEC_V2.md`：

* 丢给 **Cursor / Claude / GPT-4o / Copilot**
* 要求它：

  > “按此文档生成 Quietly v2 的 Xcode 工程骨架与核心代码”

---



* 🔧 **把这份 spec 拆成「文件级任务清单」**
