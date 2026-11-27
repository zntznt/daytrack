import Foundation

/// For tests and UI tests.
public final class InMemoryRecordStore: RecordStore, @unchecked Sendable {
    private let lock = NSLock()
    private var record: Record?

    public init(_ record: Record? = nil) { self.record = record }

    public func load() throws -> LoadResult {
        lock.withLock { record.map(LoadResult.loaded) ?? .empty }
    }

    public func save(_ record: Record) throws {
        lock.withLock { self.record = record }
    }

    public func eraseAll() throws {
        lock.withLock { record = nil }
    }
}

public final class InMemoryDeviceStateStore: DeviceStateStore, @unchecked Sendable {
    private let lock = NSLock()
    private var state: DeviceState

    public init(_ state: DeviceState = DeviceState()) { self.state = state }

    public func load() throws -> DeviceState { lock.withLock { state } }

    public func save(_ state: DeviceState) throws {
        lock.withLock { self.state = state }
    }
}

public struct FixedClock: Clock {
    public var now: Date

    public init(_ now: Date) { self.now = now }
}
