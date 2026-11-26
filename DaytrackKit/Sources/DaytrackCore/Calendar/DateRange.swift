import Foundation

/// An inclusive span of local calendar dates.
public struct DateRange: Hashable, Codable, Sendable {
    public let start: DayKey
    public let end: DayKey

    /// Returns nil when end is before start.
    public init?(start: DayKey, end: DayKey) {
        guard start <= end else { return nil }
        self.start = start
        self.end = end
    }

    /// The n days ending on `end`, inclusive. n must be at least 1.
    public static func last(_ n: Int, endingOn end: DayKey) -> DateRange {
        precondition(n >= 1, "a range has at least one day")
        return DateRange(start: end.adding(days: -(n - 1)), end: end)!
    }

    /// Number of days, counting both ends.
    public var count: Int { start.days(to: end) + 1 }

    public func contains(_ day: DayKey) -> Bool { start <= day && day <= end }

    public var days: [DayKey] { (0..<count).map { start.adding(days: $0) } }
}
