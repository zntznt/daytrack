import Foundation

public enum LoadResult: Hashable, Sendable {
    /// Nothing stored yet.
    case empty
    case loaded(Record)
    /// The stored file could not be read. It was moved aside to `keptAt` and is never overwritten.
    case unreadable(keptAt: URL)
}

public protocol RecordStore: Sendable {
    func load() throws -> LoadResult
    func save(_ record: Record) throws
    /// Deletes everything this store keeps, moved-aside unreadable copies included. Afterwards `load()` is `.empty`.
    func eraseAll() throws
}

extension RecordStore {
    /// A wrapper with no files of its own cannot erase; erase through the store it wraps.
    public func eraseAll() throws { throw CocoaError(.featureUnsupported) }
}

public protocol DeviceStateStore: Sendable {
    /// A missing state loads as `DeviceState()`.
    func load() throws -> DeviceState
    func save(_ state: DeviceState) throws
}

public protocol Clock: Sendable {
    var now: Date { get }
}

public protocol ReminderScheduling: Sendable {
    func replan(record: Record, now: Date)
    func removeAll()
}

public protocol WidgetPublishing: Sendable {
    func publish(record: Record, now: Date)
}
