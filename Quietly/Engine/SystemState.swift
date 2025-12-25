import Foundation

public struct SystemState: Sendable, Equatable {
    public let timestampMs: Int64

    public let lidClosed: Bool
    public let onBattery: Bool
    public let externalDisplayConnected: Bool
    public let bluetoothEnabled: Bool

    public init(
        timestampMs: Int64,
        lidClosed: Bool,
        onBattery: Bool,
        externalDisplayConnected: Bool,
        bluetoothEnabled: Bool
    ) {
        self.timestampMs = timestampMs
        self.lidClosed = lidClosed
        self.onBattery = onBattery
        self.externalDisplayConnected = externalDisplayConnected
        self.bluetoothEnabled = bluetoothEnabled
    }

    public static func now(
        lidClosed: Bool,
        onBattery: Bool,
        externalDisplayConnected: Bool,
        bluetoothEnabled: Bool
    ) -> SystemState {
        SystemState(
            timestampMs: Int64(Date().timeIntervalSince1970 * 1000),
            lidClosed: lidClosed,
            onBattery: onBattery,
            externalDisplayConnected: externalDisplayConnected,
            bluetoothEnabled: bluetoothEnabled
        )
    }
}
