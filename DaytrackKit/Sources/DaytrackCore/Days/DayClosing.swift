import Foundation

/// Whether a day can be written right now (decisions Q1).
public enum DayStatus: Hashable, Sendable {
    case future
    case today
    case yesterdayOpen(until: Date)
    case closed
}

/// What a lock-hour change does to a yesterday that is still open.
public enum LockHourChange: Hashable, Sendable {
    case applies
    case closesYesterdayNow
}

/// Day D is writable from its midnight until lockHour:00 on D+1, then closes for good.
public enum DayClosing {
    /// The first local instant at or after lockHour:00 on D+1. Lock hour 0 is D+1's midnight.
    public static func closeInstant(_ day: DayKey, lockHour: Int, tz: TimeZone) -> Date {
        precondition((0...23).contains(lockHour), "lock hour is 0 to 23")
        let next = LocalCalendar(timeZone: tz).startOfDay(day.adding(days: 1))
        if lockHour == 0 { return next }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        // .nextTime skips a DST gap to its first instant; .first picks the earlier of a repeated hour.
        return cal.nextDate(after: next.addingTimeInterval(-1), matching: DateComponents(hour: lockHour, minute: 0, second: 0),
                            matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)!
    }

    public static func status(of day: DayKey, now: Date, lockHour: Int, closedThrough: DayKey?, tz: TimeZone) -> DayStatus {
        let today = LocalCalendar(timeZone: tz).dayKey(for: now)
        if day > today { return .future }
        if let closedThrough, day <= closedThrough { return .closed }
        let close = closeInstant(day, lockHour: lockHour, tz: tz)
        guard close > now else { return .closed }
        return day == today ? .today : .yesterdayOpen(until: close)
    }

    /// The latest day closed at `now`, never earlier than `current`.
    public static func advanceClosedThrough(_ current: DayKey?, now: Date, lockHour: Int, tz: TimeZone) -> DayKey? {
        let yesterday = LocalCalendar(timeZone: tz).dayKey(for: now).adding(days: -1)
        let closed = closeInstant(yesterday, lockHour: lockHour, tz: tz) <= now ? yesterday : yesterday.adding(days: -1)
        guard let current else { return closed }
        return max(current, closed)
    }

    /// `.closesYesterdayNow` when yesterday is open under `oldHour` but `newHour` has already passed.
    public static func lockHourChange(from oldHour: Int, to newHour: Int, now: Date, closedThrough: DayKey?, tz: TimeZone) -> LockHourChange {
        let yesterday = LocalCalendar(timeZone: tz).dayKey(for: now).adding(days: -1)
        guard case .yesterdayOpen = status(of: yesterday, now: now, lockHour: oldHour, closedThrough: closedThrough, tz: tz),
              closeInstant(yesterday, lockHour: newHour, tz: tz) <= now
        else { return .applies }
        return .closesYesterdayNow
    }

    /// The earlier of the next midnight (relabel) and the next close instant.
    public static func nextBoundary(now: Date, lockHour: Int, tz: TimeZone) -> Date {
        let cal = LocalCalendar(timeZone: tz)
        let today = cal.dayKey(for: now)
        let midnight = cal.startOfDay(today.adding(days: 1))
        let close = closeInstant(today.adding(days: -1), lockHour: lockHour, tz: tz)
        return close > now ? min(close, midnight) : midnight
    }
}
