import Foundation

public struct ProcessResult: Sendable, Equatable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public init(exitCode: Int32, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

public enum ProcessRunnerError: Error, Sendable {
    case launchFailed(String)
    case timedOut
}

public struct ProcessRunner: Sendable {
    public init() {}

    public func run(
        executableURL: URL,
        arguments: [String],
        timeoutSeconds: TimeInterval
    ) throws -> ProcessResult {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.launchFailed(error.localizedDescription)
        }

        if timeoutSeconds > 0 {
            let deadline = Date().addingTimeInterval(timeoutSeconds)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.01)
            }
            if process.isRunning {
                process.terminate()
                throw ProcessRunnerError.timedOut
            }
        } else {
            process.waitUntilExit()
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )
    }
}
