import Foundation

public struct Tracker: Identifiable, Hashable, Codable, Sendable {
    /// Words for the two ends of a numeric scale.
    public struct Anchors: Hashable, Codable, Sendable {
        public var low: String
        public var high: String

        public init(low: String, high: String) {
            self.low = low
            self.high = high
        }
    }

    /// Days the tracker was off the board, inclusive. `to == nil` means it still is.
    public struct ArchivedRange: Hashable, Codable, Sendable {
        public let from: DayKey
        public var to: DayKey?

        public init(from: DayKey, to: DayKey? = nil) {
            self.from = from
            self.to = to
        }
    }

    public let id: UUID
    public var name: String
    /// An SF Symbol name.
    public var symbol: String
    public let type: TrackerType
    /// One word per stop; empty for numeric.
    public var labels: [String]
    public var anchors: Anchors?
    public let createdAt: DayKey
    public var archivedRanges: [ArchivedRange]

    public init(
        id: UUID = UUID(), name: String, symbol: String, type: TrackerType,
        labels: [String]? = nil, anchors: Anchors? = nil,
        createdAt: DayKey, archivedRanges: [ArchivedRange] = []
    ) {
        let labels = labels ?? type.defaultLabels
        precondition(labels.count == (type == .numeric ? 0 : type.stops), "one label per stop")
        self.id = id
        self.name = name
        self.symbol = symbol
        self.type = type
        self.labels = labels
        self.anchors = anchors
        self.createdAt = createdAt
        self.archivedRanges = archivedRanges
    }

    /// Derived, never stored: the last range is still open (Q11b amendment 1).
    public var isArchived: Bool {
        guard let last = archivedRanges.last else { return false }
        return last.to == nil
    }
}
