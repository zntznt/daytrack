import Foundation

/// A local calendar date with no time or offset. Codable as "YYYY-MM-DD".
public struct DayKey: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Returns nil when the components do not name a real Gregorian date.
    public init?(year: Int, month: Int, day: Int) {
        let comps = DateComponents(year: year, month: month, day: day)
        guard (1...9999).contains(year), comps.isValidDate(in: DayKey.utc) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses exactly "YYYY-MM-DD".
    public init?(_ string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2])
        else { return nil }
        self.init(year: y, month: m, day: d)
    }

    public var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Pure date arithmetic; no time zone or daylight saving is involved.
    public func adding(days: Int) -> DayKey {
        let date = DayKey.utc.date(byAdding: .day, value: days, to: utcMidnight)!
        return DayKey(utcDate: date)
    }

    /// Whole days from self to other (positive when other is later).
    public func days(to other: DayKey) -> Int {
        DayKey.utc.dateComponents([.day], from: utcMidnight, to: other.utcMidnight).day!
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    static let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    var utcMidnight: Date {
        DayKey.utc.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private init(utcDate: Date) {
        let c = DayKey.utc.dateComponents([.year, .month, .day], from: utcDate)
        self.year = c.year!
        self.month = c.month!
        self.day = c.day!
    }
}

extension DayKey: CustomStringConvertible {
    public var description: String { isoString }
}

extension DayKey: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let key = DayKey(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a YYYY-MM-DD date: \(string)")
        }
        self = key
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(isoString)
    }
}
