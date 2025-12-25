import Foundation
import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var isPaused: Bool
    @Published var ruleConfigs: [RuleConfig]

    @Published var lastState: SystemState?
    @Published var recentEvents: [ActionEvent] = []

    private let ruleStore: RuleStore

    @AppStorage("showNotifications") private var showNotifications = true

    init(ruleStore: RuleStore) {
        self.ruleStore = ruleStore
        self.isPaused = ruleStore.loadPaused()
        self.ruleConfigs = ruleStore.loadConfigs().sorted { $0.id.rawValue < $1.id.rawValue }
    }

    func reloadFromStore() {
        isPaused = ruleStore.loadPaused()
        ruleConfigs = ruleStore.loadConfigs().sorted { $0.id.rawValue < $1.id.rawValue }
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        ruleStore.savePaused(paused)
    }

    func setRuleEnabled(_ id: RuleID, enabled: Bool) {
        if let index = ruleConfigs.firstIndex(where: { $0.id == id }) {
            ruleConfigs[index].enabled = enabled
        } else {
            ruleConfigs.append(RuleConfig(id: id, enabled: enabled))
        }
        ruleStore.saveConfigs(ruleConfigs)
    }

    func handleStateUpdated(_ state: SystemState) {
        lastState = state
    }

    func handleActionEvent(_ event: ActionEvent) {
        recentEvents.insert(event, at: 0)
        if recentEvents.count > 20 {
            recentEvents.removeLast(recentEvents.count - 20)
        }

        guard showNotifications else { return }

        switch event.result {
        case .skipped:
            return
        case .success:
            NotificationManager.shared.ensureAuthorizationRequested()
            NotificationManager.shared.post(
                title: "Quietly",
                body: notificationBody(for: event)
            )
        case .failed:
            NotificationManager.shared.ensureAuthorizationRequested()
            NotificationManager.shared.post(
                title: "Quietly",
                body: notificationBody(for: event)
            )
        }
    }

    private func notificationBody(for event: ActionEvent) -> String {
        let actionText: String
        switch event.action {
        case .setBluetooth(let on):
            actionText = on ? "蓝牙已开启" : "蓝牙已关闭"
        case .setPowerMode(let mode):
            switch mode {
            case .low:
                actionText = "能耗模式已切换为低电量"
            case .automatic:
                actionText = "能耗模式已切换为自动"
            }
        }

        switch event.result {
        case .success:
            return "✅ \(actionText)"
        case .failed(let message):
            return "❌ \(actionText)（\(message)）"
        case .skipped:
            return ""
        }
    }
}
