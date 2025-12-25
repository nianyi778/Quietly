import Foundation

public protocol RuleStore: Sendable {
    func loadConfigs() -> [RuleConfig]
    func saveConfigs(_ configs: [RuleConfig])

    func loadPaused() -> Bool
    func savePaused(_ paused: Bool)
}

public final class UserDefaultsRuleStore: RuleStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadConfigs() -> [RuleConfig] {
        RuleID.allCases.map { id in
            RuleConfig(id: id, enabled: defaults.bool(forKey: Self.ruleKey(id)))
        }.map { config in
            if defaults.object(forKey: Self.ruleKey(config.id)) == nil {
                return RuleConfig(id: config.id, enabled: Self.defaultEnabled(config.id))
            }
            return config
        }
    }

    public func saveConfigs(_ configs: [RuleConfig]) {
        for config in configs {
            defaults.set(config.enabled, forKey: Self.ruleKey(config.id))
        }
    }

    public func loadPaused() -> Bool {
        defaults.bool(forKey: Self.pausedKey)
    }

    public func savePaused(_ paused: Bool) {
        defaults.set(paused, forKey: Self.pausedKey)
    }

    private static let pausedKey = "quietly.paused"

    private static func ruleKey(_ id: RuleID) -> String {
        "quietly.rule.\(id.rawValue).enabled"
    }

    private static func defaultEnabled(_ id: RuleID) -> Bool {
        switch id {
        case .lidCloseBluetoothOff, .lidOpenBluetoothOn:
            return true
        case .onBatteryPowerSave:
            return false
        }
    }
}
