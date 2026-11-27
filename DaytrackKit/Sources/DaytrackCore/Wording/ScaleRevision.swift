import Foundation

public enum WordingError: Error, Hashable, Sendable {
    case stopCountIsFixed
}

/// The tracker's wording changed on `effectiveFrom`; these were the words before it (Q6).
public struct ScaleRevision: Hashable, Sendable {
    public let trackerId: UUID
    /// An absolute date, never an offset (§6).
    public let effectiveFrom: DayKey
    /// One per stop, as `Tracker.labels` holds them: empty for numeric.
    public let previousLabels: [String]
    /// Numeric endpoints before the change.
    public let previousAnchors: Tracker.Anchors?

    /// Throws `.stopCountIsFixed` when `previousLabels` does not match the tracker's stops.
    public init(tracker: Tracker, effectiveFrom: DayKey, previousLabels: [String], previousAnchors: Tracker.Anchors? = nil) throws {
        guard previousLabels.count == tracker.labels.count else { throw WordingError.stopCountIsFixed }
        self.trackerId = tracker.id
        self.effectiveFrom = effectiveFrom
        self.previousLabels = previousLabels
        self.previousAnchors = previousAnchors
    }
}
