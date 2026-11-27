import Foundation

/// One day's rows among the selected trackers active that day (Q5).
public struct RowCounts: Hashable, Sendable {
    public let written: Int
    public let skipped: Int
    public let blank: Int

    public init(written: Int, skipped: Int, blank: Int) {
        self.written = written
        self.skipped = skipped
        self.blank = blank
    }

    public init(entry: DayEntry?, day: DayKey, trackers: [Tracker]) {
        var written = 0, skipped = 0, blank = 0
        for t in trackers where ActiveSpan.isActive(t, on: day) {
            switch entry?.values[t.id] {
            case .set: written += 1
            case .skip: skipped += 1
            case nil: blank += 1
            }
        }
        self.init(written: written, skipped: skipped, blank: blank)
    }
}

/// Days in a range among the selected trackers (Q5). A day with no selected tracker active is not counted.
public struct DayCounts: Hashable, Sendable {
    /// Days with at least one set value.
    public let written: Int
    /// Days with skips and no set value.
    public let skippedOnly: Int
    /// Days with nothing at all.
    public let blank: Int

    public init(written: Int, skippedOnly: Int, blank: Int) {
        self.written = written
        self.skippedOnly = skippedOnly
        self.blank = blank
    }

    public init(entries: [DayKey: DayEntry], range: DateRange, trackers: [Tracker]) {
        var written = 0, skippedOnly = 0, blank = 0
        for day in range.days {
            let rows = RowCounts(entry: entries[day], day: day, trackers: trackers)
            if rows.written > 0 { written += 1 }
            else if rows.skipped > 0 { skippedOnly += 1 }
            else if rows.blank > 0 { blank += 1 }
        }
        self.init(written: written, skippedOnly: skippedOnly, blank: blank)
    }
}
