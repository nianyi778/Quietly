import Foundation

@QuietlyEngineActor
public final class AutomationEngine {
    public struct Callbacks: Sendable {
        public var onStateUpdated: (@Sendable @MainActor (SystemState) -> Void)?
        public var onActionEvent: (@Sendable @MainActor (ActionEvent) -> Void)?

        public init(
            onStateUpdated: (@Sendable @MainActor (SystemState) -> Void)? = nil,
            onActionEvent: (@Sendable @MainActor (ActionEvent) -> Void)? = nil
        ) {
            self.onStateUpdated = onStateUpdated
            self.onActionEvent = onActionEvent
        }
    }

    private let stateReader: SystemStateReading
    private let ruleStore: RuleStore
    private let executor: ActionExecutor

    private let pollIntervalSeconds: TimeInterval
    private var pollTask: Task<Void, Never>?

    private var previousState: SystemState?

    public init(
        stateReader: SystemStateReading,
        ruleStore: RuleStore,
        executor: ActionExecutor,
        pollIntervalSeconds: TimeInterval = 5,
        callbacks: Callbacks = Callbacks()
    ) {
        self.stateReader = stateReader
        self.ruleStore = ruleStore
        self.executor = executor
        self.pollIntervalSeconds = pollIntervalSeconds
        self.callbacks = callbacks
    }

    private var callbacks: Callbacks

    public func updateCallbacks(_ callbacks: Callbacks) {
        self.callbacks = callbacks
    }

    public func start() {
        guard pollTask == nil else { return }

        pollTask = Task.detached(priority: .utility) { [pollIntervalSeconds, weak self] in
            while !Task.isCancelled {
                if let self {
                    await self.tick()
                }
                try? await Task.sleep(nanoseconds: UInt64(pollIntervalSeconds * 1_000_000_000))
            }
        }
    }

    public func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func tick() async {
        if ruleStore.loadPaused() {
            return
        }

        let currentState: SystemState
        do {
            currentState = try stateReader.collect()
        } catch {
            return
        }

        let callbacks = self.callbacks
        Task { @MainActor in
            callbacks.onStateUpdated?(currentState)
        }

        guard let previousState else {
            self.previousState = currentState
            return
        }

        let enabledRules = Set(ruleStore.loadConfigs().filter { $0.enabled }.map { $0.id })
        let actions = RuleEngine.evaluate(prev: previousState, curr: currentState, enabledRules: enabledRules)

        for action in actions {
            let result = executor.execute(action: action, currentState: currentState)
            let event = ActionEvent(
                timestampMs: currentState.timestampMs,
                action: action,
                result: result
            )
            if case .skipped = result {
                // SKIPPED 不通知、不上报
            } else {
                let callbacks = self.callbacks
                Task { @MainActor in
                    callbacks.onActionEvent?(event)
                }
            }
        }

        self.previousState = currentState
    }
}
