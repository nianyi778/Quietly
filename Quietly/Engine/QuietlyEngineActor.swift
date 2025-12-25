import Foundation

@globalActor
public enum QuietlyEngineActor {
    public actor Executor {}
    public static let shared = Executor()
}
