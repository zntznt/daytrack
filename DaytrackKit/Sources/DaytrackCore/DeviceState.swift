import Foundation

/// What only this phone knows. Never exported and never part of the record (Q2, Q7b).
public struct DeviceState: Hashable, Codable, Sendable {
    public var lastFullCopyAt: Date?
    /// shortcut: opaque bytes until the ReportDraft type lands in M6.01.
    public var reportDraft: Data?
    public var remindersScheduledThrough: DayKey?
    /// The day-one-written screen has been shown ([O11]). Erase resets it with the rest.
    public var dayOneScreenShown: Bool

    public init(lastFullCopyAt: Date? = nil, reportDraft: Data? = nil, remindersScheduledThrough: DayKey? = nil,
                dayOneScreenShown: Bool = false) {
        self.lastFullCopyAt = lastFullCopyAt
        self.reportDraft = reportDraft
        self.remindersScheduledThrough = remindersScheduledThrough
        self.dayOneScreenShown = dayOneScreenShown
    }

    /// A file saved before a field existed still opens, with that field at its default.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(lastFullCopyAt: try c.decodeIfPresent(Date.self, forKey: .lastFullCopyAt),
                  reportDraft: try c.decodeIfPresent(Data.self, forKey: .reportDraft),
                  remindersScheduledThrough: try c.decodeIfPresent(DayKey.self, forKey: .remindersScheduledThrough),
                  dayOneScreenShown: try c.decodeIfPresent(Bool.self, forKey: .dayOneScreenShown) ?? false)
    }
}
