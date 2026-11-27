import Foundation

/// The days a tracker can hold values and count blanks (Q11b).
public enum ActiveSpan {
    public static func isActive(_ tracker: Tracker, on day: DayKey) -> Bool {
        guard day >= tracker.createdAt else { return false }
        return !tracker.archivedRanges.contains { range in
            range.from <= day && (range.to.map { day <= $0 } ?? true)
        }
    }
}
