import Foundation

@QuietlyEngineActor
public final class ActionExecutor {
    private let bluetoothController: BluetoothController
    private let privilegedRunner: PrivilegedCommandRunner

    public init(
        bluetoothController: BluetoothController = BluetoothController(),
        privilegedRunner: PrivilegedCommandRunner = PrivilegedCommandRunner()
    ) {
        self.bluetoothController = bluetoothController
        self.privilegedRunner = privilegedRunner
    }

    public func execute(action: Action, currentState: SystemState) -> ActionResult {
        switch action {
        case .setBluetooth(let on):
            return setBluetooth(on: on, currentState: currentState)
        case .setPowerMode(let mode):
            return setPowerMode(mode)
        }
    }

    private func setBluetooth(on: Bool, currentState: SystemState) -> ActionResult {
        // Skip if already in desired state
        if currentState.bluetoothEnabled == on {
            return .skipped
        }

        // Check if Bluetooth is available
        guard bluetoothController.isAvailable else {
            return .failed(message: "Bluetooth not available")
        }

        // Set power state using native API
        let success = bluetoothController.setPower(on)
        if success {
            return .success
        } else {
            return .failed(message: "Failed to set Bluetooth power to \(on ? "on" : "off")")
        }
    }

    private func setPowerMode(_ mode: PowerMode) -> ActionResult {
        let powermodeValue: Int
        switch mode {
        case .automatic:
            powermodeValue = 0
        case .low:
            powermodeValue = 1
        }

        let command = "/usr/bin/pmset -a powermode \(powermodeValue)"

        do {
            let result = try privilegedRunner.runPrivilegedShellCommand(command, timeoutSeconds: 30)
            if result.exitCode == 0 {
                return .success
            }

            let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            let combined = [stderr, stdout].filter { !$0.isEmpty }.joined(separator: " | ")

            if combined.localizedCaseInsensitiveContains("User canceled") || combined.localizedCaseInsensitiveContains("cancel") {
                return .failed(message: "用户取消授权")
            }

            if combined.isEmpty {
                return .failed(message: "pmset 执行失败 (exitCode=\(result.exitCode))")
            }
            return .failed(message: combined)
        } catch {
            return .failed(message: "执行失败：\(error)")
        }
    }
}
