import CoreGraphics
import Foundation
import IOKit.ps

public enum SystemStateReadError: Error, Sendable {
    case failedToRead(String)
}

public protocol SystemStateReading: Sendable {
    func collect() throws -> SystemState
}

public struct DefaultSystemStateReader: SystemStateReading {
    private let processRunner: ProcessRunner
    private let bluetoothController: BluetoothController

    public init(
        processRunner: ProcessRunner = ProcessRunner(),
        bluetoothController: BluetoothController = BluetoothController()
    ) {
        self.processRunner = processRunner
        self.bluetoothController = bluetoothController
    }

    public func collect() throws -> SystemState {
        let lidClosed = try readClamshellClosed()
        let onBattery = try readOnBattery()
        let externalDisplayConnected = try readExternalDisplayConnected()
        let bluetoothEnabled = readBluetoothEnabled()

        return .now(
            lidClosed: lidClosed,
            onBattery: onBattery,
            externalDisplayConnected: externalDisplayConnected,
            bluetoothEnabled: bluetoothEnabled
        )
    }

    private func readClamshellClosed() throws -> Bool {
        let url = URL(fileURLWithPath: "/usr/sbin/ioreg")
        let result = try processRunner.run(
            executableURL: url,
            arguments: ["-r", "-k", "AppleClamshellState"],
            timeoutSeconds: 0.25
        )

        if result.exitCode != 0 {
            throw SystemStateReadError.failedToRead("ioreg exitCode=\(result.exitCode) stderr=\(result.stderr)")
        }

        let output = result.stdout
        
        // 精确匹配 "AppleClamshellState" = Yes 或 No
        // 使用正则表达式确保只匹配这个特定的键
        if let range = output.range(of: #""AppleClamshellState"\s*=\s*(Yes|No)"#, options: .regularExpression) {
            let match = String(output[range])
            if match.contains("Yes") { return true }
            if match.contains("No") { return false }
        }

        // Fallback: 查找 AppleClamshellState 后的值
        if let keyRange = output.range(of: "AppleClamshellState") {
            // 获取这一行
            let afterKey = output[keyRange.upperBound...]
            // 查找这行的值
            if let lineEnd = afterKey.firstIndex(of: "\n") {
                let line = String(afterKey[..<lineEnd])
                if line.contains("= Yes") { return true }
                if line.contains("= No") { return false }
            }
        }

        throw SystemStateReadError.failedToRead("Unable to parse AppleClamshellState from ioreg output")
    }

    private func readOnBattery() throws -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            throw SystemStateReadError.failedToRead("IOPSCopyPowerSourcesInfo returned nil")
        }

        guard let sourceType = IOPSGetProvidingPowerSourceType(info)?.takeRetainedValue() else {
            throw SystemStateReadError.failedToRead("IOPSGetProvidingPowerSourceType returned nil")
        }

        return (sourceType as String) == (kIOPSBatteryPowerValue as String)
    }

    private func readExternalDisplayConnected() throws -> Bool {
        var displayCount: UInt32 = 0
        var err = CGGetOnlineDisplayList(0, nil, &displayCount)
        if err != .success {
            throw SystemStateReadError.failedToRead("CGGetOnlineDisplayList(count) failed: \(err)")
        }

        var displays = Array(repeating: CGDirectDisplayID(0), count: Int(displayCount))
        err = CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
        if err != .success {
            throw SystemStateReadError.failedToRead("CGGetOnlineDisplayList(list) failed: \(err)")
        }

        return displays.contains { CGDisplayIsBuiltin($0) == 0 }
    }

    private func readBluetoothEnabled() -> Bool {
        // Use native IOBluetooth API via BluetoothController
        guard bluetoothController.isAvailable else {
            return false
        }
        return bluetoothController.isPoweredOn
    }
}
