import Foundation

/// The one source for every "not enough": a count, a threshold and what remains (HANDOFF §5 rule 3).
public struct Shortfall: Hashable, Sendable {
    public let count: Int
    public let threshold: Int
    /// 0 once the floor is met.
    public let remaining: Int

    public init(count: Int, threshold: Int) {
        self.count = count
        self.threshold = threshold
        remaining = max(0, threshold - count)
    }

    public var passes: Bool { remaining == 0 }
}

/// Honesty floors (§6, Q5). Only set values count; skips and blanks never do.
public enum Floors {
    /// Set values per tracker a report needs, in the latest era inside the range.
    public static let report = 14
    /// Days on which both trackers of a pair are set (M5.01 applies it).
    public static let pair = 12
    /// historyEmpty (§9): the chart and this week arrive at 1 day, a line at 2, a split at 12.
    public static let historyChart = 1
    public static let historyLine = 2
    public static let historySplit = pair

    public static func report(_ tracker: Tracker, range: DateRange, record: Record) -> Shortfall {
        Shortfall(count: TrackerSummary(tracker: tracker, range: range, record: record).n, threshold: report)
    }

    /// The builder can generate when at least one selected tracker passes (Q5).
    public static func builderCanGenerate(selected: [Tracker], range: DateRange, record: Record) -> Bool {
        selected.contains { report($0, range: range, record: record).passes }
    }
}
