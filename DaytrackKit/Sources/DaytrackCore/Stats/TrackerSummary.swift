import Foundation

/// The one era-windowing helper (design-review High 9). Every number about a tracker over a range comes from here.
/// All counts cover `windowedRange`: the part of the range after its most recent revision (§6, Q5 amendment).
public struct TrackerSummary: Hashable, Sendable {
    /// The latest era inside the requested range.
    public let windowedRange: DateRange
    /// A revision falls inside the requested range, so `n` is reduced and a boundary must be drawn.
    public let crossesBoundary: Bool
    /// Set values only (Q5).
    public let n: Int
    public let skips: Int
    /// Days with no value, counted only where the tracker was active (Q11b).
    public let blanks: Int
    /// Means and extremes of set values on the 0–10 scale; nil when n is 0, never 0.
    public let mean: Double?
    public let high: Double?
    public let low: Double?
    /// Binary only: set values at the upper stop, out of `n`.
    public let k: Int?
    /// Ordinal only: set values per stop, lowest stop first.
    public let distribution: [Int]?
    /// Ordinal only. For an even n, the lower middle stop: a stop the user chose, never a value between two.
    public let medianIndex: Int?

    public init(tracker: Tracker, range: DateRange, record: Record) {
        let eras = Eras(record.revisions)
        let window = eras.latestEra(tracker, in: range)
        var values: [Double] = []
        var skips = 0, blanks = 0
        for day in window.days {
            switch record.entries[day]?.values[tracker.id] {
            case .set(let v): values.append(v)
            case .skip: skips += 1
            case nil: if ActiveSpan.isActive(tracker, on: day) { blanks += 1 }
            }
        }
        let indices = values.map(tracker.type.index(forValue:))

        windowedRange = window
        crossesBoundary = window != range
        n = values.count
        self.skips = skips
        self.blanks = blanks
        mean = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        high = values.max()
        low = values.min()
        k = tracker.type == .binary ? indices.filter { $0 == 1 }.count : nil
        if tracker.type == .ordinal {
            distribution = (0..<tracker.type.stops).map { i in indices.filter { $0 == i }.count }
            medianIndex = indices.isEmpty ? nil : indices.sorted()[(indices.count - 1) / 2]
        } else {
            distribution = nil
            medianIndex = nil
        }
    }
}
