import Foundation

/// A span of days that share one wording.
public struct Era: Hashable, Sendable {
    /// nil = from the tracker's first day.
    public let start: DayKey?
    /// nil = still the current wording.
    public let end: DayKey?
    public let labels: [String]
    public let anchors: Tracker.Anchors?

    public func contains(_ day: DayKey) -> Bool {
        (start.map { $0 <= day } ?? true) && (end.map { day <= $0 } ?? true)
    }
}

/// Every statistic is windowed through here so none crosses a wording boundary (rule 7, §6).
public struct Eras: Sendable {
    public let revisions: [ScaleRevision]

    public init(_ revisions: [ScaleRevision]) {
        self.revisions = revisions
    }

    /// Oldest first; the last era carries the tracker's current words.
    public func eras(for tracker: Tracker) -> [Era] {
        let revs = revisions.filter { $0.trackerId == tracker.id }.sorted { $0.effectiveFrom < $1.effectiveFrom }
        var eras: [Era] = []
        var start: DayKey?
        for rev in revs {
            eras.append(Era(start: start, end: rev.effectiveFrom.adding(days: -1), labels: rev.previousLabels, anchors: rev.previousAnchors))
            start = rev.effectiveFrom
        }
        eras.append(Era(start: start, end: nil, labels: tracker.labels, anchors: tracker.anchors))
        return eras
    }

    public func era(_ tracker: Tracker, on day: DayKey) -> Era {
        eras(for: tracker).first { $0.contains(day) }!
    }

    /// The words a value on `day` was written against.
    public func labels(_ tracker: Tracker, on day: DayKey) -> [String] {
        era(tracker, on: day).labels
    }

    public func anchors(_ tracker: Tracker, on day: DayKey) -> Tracker.Anchors? {
        era(tracker, on: day).anchors
    }

    /// The part of `range` after the most recent revision inside it (Q5 amendment).
    public func latestEra(_ tracker: Tracker, in range: DateRange) -> DateRange {
        let start = boundaries(tracker, in: range).last ?? range.start
        return DateRange(start: start, end: range.end)!
    }

    /// Revision dates that split `range`, oldest first. A revision on `range.start` splits nothing.
    public func boundaries(_ tracker: Tracker, in range: DateRange) -> [DayKey] {
        revisions.filter { $0.trackerId == tracker.id && range.start < $0.effectiveFrom && $0.effectiveFrom <= range.end }
            .map(\.effectiveFrom).sorted()
    }
}
