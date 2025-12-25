import Foundation

public enum RuleID: String, CaseIterable, Sendable {
    case lidCloseBluetoothOff = "LidClose_BluetoothOff"
    case lidOpenBluetoothOn = "LidOpen_BluetoothOn"
    case onBatteryPowerSave = "OnBattery_PowerSave"
    
    /// 中文显示名称
    public var displayName: String {
        switch self {
        case .lidCloseBluetoothOff:
            return "合盖时关闭蓝牙"
        case .lidOpenBluetoothOn:
            return "开盖时开启蓝牙"
        case .onBatteryPowerSave:
            return "不充电时切低电量"
        }
    }
    
    /// SF Symbol 图标名称
    public var iconName: String {
        switch self {
        case .lidCloseBluetoothOff:
            return "laptopcomputer.and.arrow.down"
        case .lidOpenBluetoothOn:
            return "laptopcomputer"
        case .onBatteryPowerSave:
            return "battery.50"
        }
    }
}

public struct RuleConfig: Sendable, Equatable {
    public let id: RuleID
    public var enabled: Bool

    public init(id: RuleID, enabled: Bool) {
        self.id = id
        self.enabled = enabled
    }
}
