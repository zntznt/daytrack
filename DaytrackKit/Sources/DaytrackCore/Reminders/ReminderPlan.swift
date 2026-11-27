import Foundation

/// The daily reminder's coming fires (decisions Q10 and its amendment 2). No UserNotifications here.
public enum ReminderPlan {
    /// One non-repeating fire at a floating local time: `fire.timeZone` is nil.
    public struct Item: Hashable, Sendable {
        public let day: DayKey
        public let fire: DateComponents
    }

    /// Fires for today and the days after it, up to `horizonDays` days in all.
    /// A day is left out when no tracker is active on it or its board has no blanks (HANDOFF §9 boardEmpty);
    /// today is also left out once its time has passed. Earlier days are never re-fired.
    public static func make(reminderAt: Settings.ReminderTime?, now: Date, record: Record, tz: TimeZone, horizonDays: Int = 14) -> [Item] {
        guard let reminderAt else { return [] }
        let cal = LocalCalendar(timeZone: tz)
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = tz
        let today = cal.dayKey(for: now)
        return (0..<max(horizonDays, 0)).compactMap { offset in
            let day = today.adding(days: offset)
            let fire = DateComponents(year: day.year, month: day.month, day: day.day, hour: reminderAt.hour, minute: reminderAt.minute)
            guard RowCounts(entry: record.entries[day], day: day, trackers: record.trackers).blank > 0 else { return nil }
            if offset == 0, let at = gregorian.date(from: fire), at <= now { return nil }
            return Item(day: day, fire: fire)
        }
    }
}
