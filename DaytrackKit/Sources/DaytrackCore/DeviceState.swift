import Foundation

/// What only this phone knows. Never exported and never part of the record (Q2, Q7b).
public struct DeviceState: Hashable, Codable, Sendable {
    public var lastFullCopyAt: Date?
    /// shortcut: opaque bytes until the ReportDraft type lands in M6.01.
    public var reportDraft: Data?
    public var remindersScheduledThrough: DayKey?

    public init(lastFullCopyAt: Date? = nil, reportDraft: Data? = nil, remindersScheduledThrough: DayKey? = nil) {
        self.lastFullCopyAt = lastFullCopyAt
        self.reportDraft = reportDraft
        self.remindersScheduledThrough = remindersScheduledThrough
    }
}
