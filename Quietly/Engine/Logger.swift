import Foundation

public struct RingBuffer<T: Sendable & Equatable>: Sendable, Equatable {
    private var storage: [T] = []
    private let capacity: Int

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    public var items: [T] { storage }

    public mutating func append(_ item: T) {
        storage.append(item)
        if storage.count > capacity {
            storage.removeFirst(storage.count - capacity)
        }
    }
}
