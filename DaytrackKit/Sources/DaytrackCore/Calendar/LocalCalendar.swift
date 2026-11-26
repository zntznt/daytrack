import Foundation

/// Maps instants to local calendar dates in one time zone (Gregorian).
public struct LocalCalendar: Sendable {
    public let timeZone: TimeZone
    private let calendar: Calendar

    public init(timeZone: TimeZone) {
        self.timeZone = timeZone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        self.calendar = cal
    }

    /// The local calendar date of `date` in this time zone.
    public func dayKey(for date: Date) -> DayKey {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: c.year!, month: c.month!, day: c.day!)!
    }

    /// The first instant of `day` in this time zone.
    public func startOfDay(_ day: DayKey) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: 12))!)
    }

    public func adding(days: Int, to day: DayKey) -> DayKey {
        day.adding(days: days)
    }

    /// 1 = Sunday … 7 = Saturday, as Foundation's Gregorian calendar numbers them.
    public func weekday(of day: DayKey) -> Int {
        DayKey.utc.component(.weekday, from: day.utcMidnight)
    }
}
