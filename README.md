# Quietly

**macOS 菜单栏情境自动化工具**

Quietly 是一个轻量级的 macOS 菜单栏应用，通过检测系统状态变化（如合盖、电源、外接显示器、蓝牙等），自动执行预设的动作。

---

## ✨ 功能特性

- 🔋 **状态驱动**：基于系统状态轮询 + 差分检测，而非事件监听，更加稳定可靠
- ⚡ **自动化规则**：
  - 合盖时自动关闭蓝牙
  - 开盖时自动恢复蓝牙
  - 使用电池时自动进入省电模式
- 🖥️ **菜单栏常驻**：无 Dock 图标，不打扰你的工作
- 🪶 **轻量高效**：CPU 占用 < 0.5%，内存 < 50MB

---

## 📦 安装

### 从源码构建

1. 克隆仓库：
   ```bash
   git clone https://github.com/your-username/Quietly.git
   cd Quietly
   ```

2. 使用 Xcode 打开项目：
   ```bash
   open Quietly.xcodeproj
   ```

3. 或使用命令行构建：
   ```bash
   xcodebuild -project Quietly.xcodeproj -scheme Quietly -configuration Release build
   ```

4. 构建完成后，将 `Quietly.app` 拖入 `/Applications` 文件夹

### 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel Mac

---

## 🚀 使用方法

1. 启动 Quietly 后，它会常驻在**菜单栏**（屏幕右上角）
2. 点击菜单栏图标可以：
   - 查看当前系统状态
   - 启用/禁用自动化规则
   - 查看最近执行的动作
3. 首次使用蓝牙控制功能需要安装 `blueutil`：
   ```bash
   brew install blueutil
   ```

---

## 🔧 技术架构

```
┌────────────────────────────────────┐
│           AppKit Shell              │
│   ┌──────────────┐                 │
│   │ Status Bar UI│  SwiftUI View   │
│   └──────────────┘                 │
│            │                       │
│            ▼                       │
│     AutomationEngine               │
│   ┌──────────────────────────┐    │
│   │  StateMonitor (Polling)   │    │
│   │  RuleEngine (Diff-based)  │    │
│   │  ActionExecutor           │    │
│   └──────────────────────────┘    │
│            │                       │
│            ▼                       │
│     Persistence Layer              │
│   (UserDefaults)                   │
└────────────────────────────────────┘
```

### 核心设计

- **State-driven**：每 5 秒轮询系统状态，通过前后状态差分触发规则
- **边沿触发**：只在状态变化时执行动作，避免重复操作
- **幂等执行**：动作执行前检查当前状态，已满足则跳过

---

## 📁 项目结构

```
Quietly/
├── App/
│   └── StatusBarController.swift   # 菜单栏控制器
├── Engine/
│   ├── AutomationEngine.swift      # 核心引擎
│   ├── RuleEngine.swift            # 规则引擎
│   ├── SystemState.swift           # 系统状态模型
│   ├── SystemStateReader.swift     # 状态采集器
│   ├── ActionExecutor.swift        # 动作执行器
│   └── RuleStore.swift             # 规则存储
├── UI/
│   ├── AppModel.swift              # UI 数据模型
│   └── MenuPopoverView.swift       # 菜单弹窗视图
└── QuietlyApp.swift                # 应用入口
```

---

## 🛠️ 开发

### 运行测试

```bash
xcodebuild -project Quietly.xcodeproj -scheme Quietly -destination 'platform=macOS' test
```

### 代码规范

- Swift 6 严格并发检查
- 使用 `@QuietlyEngineActor` 隔离引擎逻辑
- 遵循 State-driven 架构

---

## 📋 路线图

- [x] Phase 1: 核心引擎 + 基础规则
- [ ] Phase 2: 规则详情页 + 条件开关
- [ ] Phase 3: 高级工作流 + 用户脚本

---

## 📄 许可证

MIT License

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

在提交代码前，请确保：
1. 通过所有测试
2. 代码符合项目规范
3. 更新相关文档
