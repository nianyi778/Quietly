import SwiftUI

struct MenuPopoverView: View {
    @ObservedObject var model: AppModel
    var onClosePopover: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部
            headerSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 规则区块
            rulesSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 状态区块
            statusSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 最近动作
            recentSection
            
            Divider()
                .padding(.vertical, 8)
            
            // 底部操作区
            footerSection
        }
        .padding(16)
        .frame(width: 320)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            // App 名称 + 状态
            HStack(spacing: 8) {
                Image(systemName: "moon.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                
                Text("Quietly")
                    .font(.headline)
                
                // 运行状态指示
                HStack(spacing: 4) {
                    Circle()
                        .fill(model.isPaused ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(model.isPaused ? "已暂停" : "运行中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 暂停开关
            Toggle("", isOn: Binding(
                get: { !model.isPaused },
                set: { model.setPaused(!$0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
    }
    
    // MARK: - Rules
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("自动化规则", systemImage: "gearshape.2")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(model.ruleConfigs, id: \.id) { config in
                ruleRow(config: config)
            }
        }
    }
    
    private func ruleRow(config: RuleConfig) -> some View {
        Toggle(isOn: Binding(
            get: { config.enabled },
            set: { model.setRuleEnabled(config.id, enabled: $0) }
        )) {
            Label(config.id.displayName, systemImage: config.id.iconName)
                .font(.body)
        }
        .toggleStyle(.checkbox)
    }
    
    // MARK: - Status
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("系统状态", systemImage: "info.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let state = model.lastState {
                // 双列布局 - 使用状态卡片
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    statusCard(
                        icon: state.lidClosed ? "laptopcomputer.closed" : "laptopcomputer",
                        label: state.lidClosed ? "已合盖" : "已开盖",
                        isActive: !state.lidClosed,  // 开盖时激活
                        activeColor: .green
                    )
                    statusCard(
                        icon: state.onBattery ? "battery.50" : "battery.100.bolt",
                        label: state.onBattery ? "使用电池" : "充电中",
                        isActive: !state.onBattery,
                        activeColor: .green
                    )
                    statusCard(
                        icon: state.externalDisplayConnected ? "display.2" : "display",
                        label: state.externalDisplayConnected ? "已外接" : "无外接",
                        isActive: state.externalDisplayConnected,
                        activeColor: .blue
                    )
                    statusCard(
                        icon: "wave.3.right",
                        label: state.bluetoothEnabled ? "蓝牙开" : "蓝牙关",
                        isActive: state.bluetoothEnabled,
                        activeColor: .blue
                    )
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("等待状态检测…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func statusCard(icon: String, label: String, isActive: Bool, activeColor: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? activeColor : .secondary)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? activeColor.opacity(0.1) : Color.secondary.opacity(0.05))
        )
    }
    
    // MARK: - Recent Actions
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("最近动作", systemImage: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if model.recentEvents.isEmpty {
                Text("暂无")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(model.recentEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                    recentEventRow(event: event)
                }
            }
        }
    }
    
    private func recentEventRow(event: ActionEvent) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconForResult(event.result))
                .font(.caption)
                .foregroundStyle(colorForResult(event.result))
            
            Text(formatAction(event.action))
                .font(.caption)
            
            Spacer()
            
            Text(formatResult(event.result))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func formatAction(_ action: Action) -> String {
        switch action {
        case .setBluetooth(let on):
            return "蓝牙 → \(on ? "开启" : "关闭")"
        case .setPowerMode(let mode):
            switch mode {
            case .low:
                return "能耗模式 → 低电量"
            case .automatic:
                return "能耗模式 → 自动"
            }
        }
    }
    
    private func formatResult(_ result: ActionResult) -> String {
        switch result {
        case .success:
            return "成功"
        case .skipped:
            return "跳过"
        case .failed:
            return "失败"
        }
    }
    
    private func iconForResult(_ result: ActionResult) -> String {
        switch result {
        case .success:
            return "checkmark.circle.fill"
        case .skipped:
            return "forward.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private func colorForResult(_ result: ActionResult) -> Color {
        switch result {
        case .success:
            return .green
        case .skipped:
            return .secondary
        case .failed:
            return .red
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 10) {
            // 设置和关于按钮
            HStack {
                Button {
                    onClosePopover?()
                    WindowManager.shared.showPreferencesWindow()
                } label: {
                    Label("偏好设置…", systemImage: "gearshape")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.001)) // 确保整个区域可点击
                        .contentShape(Rectangle())
                }
                .buttonStyle(HoverButtonStyle())
                
                Spacer()
                
                Button {
                    onClosePopover?()
                    WindowManager.shared.showAboutWindow()
                } label: {
                    Label("关于", systemImage: "info.circle")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.001))
                        .contentShape(Rectangle())
                }
                .buttonStyle(HoverButtonStyle())
            }
            .foregroundStyle(.secondary)
            
            // 退出按钮
            Button {
                NSApp.terminate(nil)
            } label: {
                Text("退出 Quietly")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Hover Button Style

struct HoverButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isHovered ? .primary : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

#Preview {
    let store = UserDefaultsRuleStore(defaults: UserDefaults(suiteName: "preview")!)
    let model = AppModel(ruleStore: store)
    return MenuPopoverView(model: model, onClosePopover: nil)
}
