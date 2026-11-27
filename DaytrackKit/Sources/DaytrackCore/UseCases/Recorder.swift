import Foundation

/// The board's single entry point. Every call advances `closedThrough`, applies the pure write,
/// saves, then publishes the widget and replans reminders (Q10), in that order.
/// A call that throws leaves both the store and `record` untouched.
public final class Recorder {
    public private(set) var record: Record
    private let store: RecordStore
    private let clock: Clock
    private let widget: WidgetPublishing
    private let reminders: ReminderScheduling
    private let tz: TimeZone

    public init(record: Record, store: RecordStore, clock: Clock, widget: WidgetPublishing,
                reminders: ReminderScheduling, tz: TimeZone = .autoupdatingCurrent) {
        self.record = record
        self.store = store
        self.clock = clock
        self.widget = widget
        self.reminders = reminders
        self.tz = tz
    }

    public func write(_ value: Double, to trackerID: UUID, on day: DayKey) throws {
        try edit(day) { entry, ctx, record in try Writes.set(value, for: Self.tracker(trackerID, in: record), in: entry, ctx) }
    }

    public func skip(_ trackerID: UUID, on day: DayKey) throws {
        try edit(day) { entry, ctx, record in try Writes.skip(Self.tracker(trackerID, in: record), in: entry, ctx) }
    }

    public func clear(_ trackerID: UUID, on day: DayKey) throws {
        try edit(day) { entry, ctx, _ in
            guard let entry else {
                // Clearing a blank is not a write, but a closed day still refuses it.
                if case .closed = ctx.status { throw WriteError.dayClosed }
                if case .future = ctx.status { throw WriteError.dayNotStarted }
                return nil
            }
            return try Writes.clear(trackerID, in: entry, ctx)
        }
    }

    public func setNote(_ note: String?, on day: DayKey) throws {
        try edit(day) { entry, ctx, _ in try Writes.setNote(note, in: entry, ctx) }
    }

    public func skipRest(day: DayKey) throws {
        try edit(day) { entry, ctx, record in try Writes.skipRest(active: record.trackers, in: entry, ctx) }
    }

    /// Closes whatever the clock has closed; call on launch, foreground and at each day boundary.
    public func refresh() throws {
        try commit { _, _ in }
    }

    /// The shared pipeline. `change` sees the record after `closedThrough` has advanced.
    func commit(_ change: (inout Record, Date) throws -> Void) throws {
        let now = clock.now
        var next = record
        next.settings.closedThrough = DayClosing.advanceClosedThrough(next.settings.closedThrough, now: now, lockHour: next.settings.lockHour, tz: tz)
        try change(&next, now)
        try store.save(next)
        record = next
        widget.publish(record: next, now: now)
        reminders.replan(record: next, now: now)
    }

    func lockHourChange(to hour: Int) -> LockHourChange {
        let now = clock.now
        let s = record.settings
        let closed = DayClosing.advanceClosedThrough(s.closedThrough, now: now, lockHour: s.lockHour, tz: tz)
        return DayClosing.lockHourChange(from: s.lockHour, to: hour, now: now, closedThrough: closed, tz: tz)
    }

    /// Applies a lock hour and closes any day it has already closed. `closedThrough` never moves back.
    func applyLockHour(_ hour: Int) throws {
        precondition((0...23).contains(hour), "lock hour is 0 to 23")
        try commit { record, now in
            record.settings.lockHour = hour
            record.settings.closedThrough = DayClosing.advanceClosedThrough(record.settings.closedThrough, now: now, lockHour: hour, tz: tz)
        }
    }

    private func edit(_ day: DayKey, _ write: (DayEntry?, WriteContext, Record) throws -> DayEntry?) throws {
        try commit { record, now in
            let s = record.settings
            let status = DayClosing.status(of: day, now: now, lockHour: s.lockHour, closedThrough: s.closedThrough, tz: tz)
            let ctx = WriteContext(day: day, status: status, now: now, tz: tz)
            if let entry = try write(record.entries[day], ctx, record) { record.entries[day] = entry }
        }
    }

    private static func tracker(_ id: UUID, in record: Record) throws -> Tracker {
        guard let t = record.trackers.first(where: { $0.id == id }) else { throw WriteError.trackerNotActive }
        return t
    }
}
