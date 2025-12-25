import Foundation

@QuietlyEngineActor
public enum RuleEngine {
    public static func evaluate(prev: SystemState, curr: SystemState, enabledRules: Set<RuleID>) -> [Action] {
        var actions: [Action] = []

        if enabledRules.contains(.lidCloseBluetoothOff) {
            if !prev.lidClosed && curr.lidClosed {
                actions.append(.setBluetooth(on: false))
            }
        }

        if enabledRules.contains(.lidOpenBluetoothOn) {
            if prev.lidClosed && !curr.lidClosed {
                actions.append(.setBluetooth(on: true))
            }
        }

        if enabledRules.contains(.onBatteryPowerSave) {
            if !prev.onBattery && curr.onBattery {
                actions.append(.setPowerMode(.low))
            }
            if prev.onBattery && !curr.onBattery {
                actions.append(.setPowerMode(.automatic))
            }
        }

        return actions
    }
}
