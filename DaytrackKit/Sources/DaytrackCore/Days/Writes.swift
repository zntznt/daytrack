import Foundation

public enum WriteError: Error, Hashable, Sendable {
    case dayClosed
    case dayNotStarted
    case trackerNotActive
    case valueOffScale
}

/// The day being written and the clock at the write.
public struct WriteContext: Sendable {
    public let day: DayKey
    public let status: DayStatus
    public let now: Date
    public let tz: TimeZone

    public init(day: DayKey, status: DayStatus, now: Date, tz: TimeZone) {
        self.day = day
        self.status = status
        self.now = now
        self.tz = tz
    }
}

/// Pure writes. Each returns the new entry or throws, leaving the input untouched.
/// Every successful call counts as a write (Q3), including notes, skips and clears.
public enum Writes {
    public static func set(_ value: Double, for tracker: Tracker, in entry: DayEntry?, _ ctx: WriteContext) throws -> DayEntry {
        try requireActive(tracker, ctx)
        let i = value.isFinite ? tracker.type.index(forValue: value) : 0
        guard value.isFinite, tracker.type.value(forIndex: i) == value else { throw WriteError.valueOffScale }
        return try write(entry, ctx) { $0.values[tracker.id] = .set(value) }
    }

    public static func skip(_ tracker: Tracker, in entry: DayEntry?, _ ctx: WriteContext) throws -> DayEntry {
        try requireActive(tracker, ctx)
        return try write(entry, ctx) { $0.values[tracker.id] = .skip }
    }

    /// Back to blank: removes the key. Clearing a blank changes nothing and is not a write.
    public static func clear(_ trackerID: UUID, in entry: DayEntry, _ ctx: WriteContext) throws -> DayEntry {
        try requireOpen(ctx)
        guard entry.values[trackerID] != nil else { return entry }
        return try write(entry, ctx) { $0.values[trackerID] = nil }
    }

    /// An empty note removes it.
    public static func setNote(_ note: String?, in entry: DayEntry?, _ ctx: WriteContext) throws -> DayEntry {
        try write(entry, ctx) { $0.note = (note?.isEmpty ?? true) ? nil : note }
    }

    /// "Skip the rest of {dayLabel}": writes skip only into blanks of trackers active that day (Q4).
    public static func skipRest(active trackers: [Tracker], in entry: DayEntry?, _ ctx: WriteContext) throws -> DayEntry {
        try write(entry, ctx) { e in
            for t in trackers where ActiveSpan.isActive(t, on: ctx.day) && e.values[t.id] == nil {
                e.values[t.id] = .skip
            }
        }
    }

    private static func requireOpen(_ ctx: WriteContext) throws {
        switch ctx.status {
        case .today, .yesterdayOpen: return
        case .closed: throw WriteError.dayClosed
        case .future: throw WriteError.dayNotStarted
        }
    }

    private static func requireActive(_ tracker: Tracker, _ ctx: WriteContext) throws {
        try requireOpen(ctx)
        guard ActiveSpan.isActive(tracker, on: ctx.day) else { throw WriteError.trackerNotActive }
    }

    private static func write(_ entry: DayEntry?, _ ctx: WriteContext, _ change: (inout DayEntry) -> Void) throws -> DayEntry {
        try requireOpen(ctx)
        precondition(entry.map { $0.date == ctx.day } ?? true, "entry belongs to another day")
        let offset = ctx.tz.secondsFromGMT(for: ctx.now)
        var e = entry ?? DayEntry(date: ctx.day, firstWrittenAt: ctx.now, lastWrittenAt: ctx.now, tzOffsetAtWrite: offset)
        change(&e)
        e.lastWrittenAt = ctx.now
        e.tzOffsetAtWrite = offset
        if LocalCalendar(timeZone: ctx.tz).dayKey(for: ctx.now) > ctx.day { e.writtenNextDay = true }
        return e
    }
}
