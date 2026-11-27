import Foundation

/// Everything written for one local date (HANDOFF §2, decisions Q3).
public struct DayEntry: Hashable, Sendable {
    public enum Origin: String, Hashable, Sendable {
        case device, `import`
    }

    public let date: DayKey
    /// Absent key = blank.
    public var values: [UUID: DayValue]
    public var note: String?
    public var firstWrittenAt: Date
    public var lastWrittenAt: Date
    /// Seconds east of GMT at the latest write.
    public var tzOffsetAtWrite: Int
    /// Some write happened after the date had passed on the local clock (Q3 amendment 1).
    public var writtenNextDay: Bool
    public var origin: Origin
    public var importedAt: Date?

    public init(
        date: DayKey, values: [UUID: DayValue] = [:], note: String? = nil,
        firstWrittenAt: Date, lastWrittenAt: Date, tzOffsetAtWrite: Int,
        writtenNextDay: Bool = false, origin: Origin = .device, importedAt: Date? = nil
    ) {
        self.date = date
        self.values = values
        self.note = note
        self.firstWrittenAt = firstWrittenAt
        self.lastWrittenAt = lastWrittenAt
        self.tzOffsetAtWrite = tzOffsetAtWrite
        self.writtenNextDay = writtenNextDay
        self.origin = origin
        self.importedAt = importedAt
    }
}
