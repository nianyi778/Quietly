import Foundation

public struct PrivilegedCommandRunner: Sendable {
    private let processRunner: ProcessRunner

    public init(processRunner: ProcessRunner = ProcessRunner()) {
        self.processRunner = processRunner
    }

    public func runPrivilegedShellCommand(_ command: String, timeoutSeconds: TimeInterval = 30) throws -> ProcessResult {
        let script = "do shell script \"\(appleScriptEscaped(command))\" with administrator privileges"
        let url = URL(fileURLWithPath: "/usr/bin/osascript")
        return try processRunner.run(
            executableURL: url,
            arguments: ["-e", script],
            timeoutSeconds: timeoutSeconds
        )
    }

    private func appleScriptEscaped(_ value: String) -> String {
        // Escape for inclusion inside an AppleScript double-quoted string
        // Order matters: backslash first.
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
