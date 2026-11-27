import Foundation

/// The range choices, grown from one record start (design-review Medium 7).
/// History ranges end today; report ranges end at `closedThrough` [O9], so a label never runs past the data (Medium 1).
public struct HistoryRanges: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case soFar, last30, last90
        /// Rolling 365 days, not the calendar year.
        case twelveMonths
    }

    public struct Option: Hashable, Sendable {
        public let kind: Kind
        public let range: DateRange
    }

    /// Empty when nothing is written yet (historyEmpty) or the record starts after `end`.
    public let options: [Option]

    public init(recordStart: DayKey?, end: DayKey?) {
        guard let recordStart, let end, let whole = DateRange(start: recordStart, end: end) else {
            options = []
            return
        }
        let age = whole.count
        guard age >= 30 else {
            options = [Option(kind: .soFar, range: whole)]
            return
        }
        options = [(Kind.last30, 30), (.last90, 90), (.twelveMonths, 365)]
            .filter { age >= $0.1 }
            .map { Option(kind: $0.0, range: .last($0.1, endingOn: end)) }
    }

    public static func history(_ record: Record, today: DayKey) -> HistoryRanges {
        HistoryRanges(recordStart: recordStart(record), end: today)
    }

    public static func report(_ record: Record) -> HistoryRanges {
        HistoryRanges(recordStart: recordStart(record), end: record.settings.closedThrough)
    }

    /// The first day with anything written: a set value (Q5). A skipped-only day is not written.
    public static func recordStart(_ record: Record) -> DayKey? {
        record.entries.values
            .filter { $0.values.values.contains { if case .set = $0 { true } else { false } } }
            .map(\.date).min()
    }
}
