import Foundation

/// Words and anchors edit freely until a closed day holds a value for the tracker;
/// after that every change is a revision effective today (Q6, rule 7). There is no correction mode.
public enum WordingEditRule {
    /// A closed day holds a set or skipped value for this tracker.
    public static func isFrozen(_ tracker: Tracker, in record: Record) -> Bool {
        guard let closedThrough = record.settings.closedThrough else { return false }
        return record.entries.values.contains { $0.date <= closedThrough && $0.values[tracker.id] != nil }
    }

    /// Applies new words to the tracker in `record`, adding a revision when the wording is frozen.
    public static func edit(_ trackerId: UUID, labels: [String], anchors: Tracker.Anchors?, in record: Record, today: DayKey) throws -> Record {
        guard let i = record.trackers.firstIndex(where: { $0.id == trackerId }) else { preconditionFailure("unknown tracker") }
        let old = record.trackers[i]
        guard labels.count == old.labels.count else { throw WordingError.stopCountIsFixed }
        guard labels != old.labels || anchors != old.anchors else { return record }

        var out = record
        out.trackers[i].labels = labels
        out.trackers[i].anchors = anchors
        guard isFrozen(old, in: record) else { return out }

        // A second edit today keeps the words from before today; reverting them drops the boundary.
        if let r = out.revisions.firstIndex(where: { $0.trackerId == trackerId && $0.effectiveFrom == today }) {
            let rev = out.revisions[r]
            if rev.previousLabels == labels && rev.previousAnchors == anchors { out.revisions.remove(at: r) }
            return out
        }
        out.revisions.append(try ScaleRevision(tracker: old, effectiveFrom: today, previousLabels: old.labels, previousAnchors: old.anchors))
        return out
    }
}
