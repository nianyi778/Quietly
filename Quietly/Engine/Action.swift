import Foundation

public enum PowerMode: Sendable, Equatable {
    case automatic
    case low
}

public enum Action: Sendable, Equatable {
    case setBluetooth(on: Bool)
    case setPowerMode(PowerMode)
}

public enum ActionResult: Sendable, Equatable {
    case success
    case skipped
    case failed(message: String)
}

public struct ActionEvent: Sendable, Equatable {
    public let timestampMs: Int64
    public let action: Action
    public let result: ActionResult

    public init(timestampMs: Int64, action: Action, result: ActionResult) {
        self.timestampMs = timestampMs
        self.action = action
        self.result = result
    }
}
