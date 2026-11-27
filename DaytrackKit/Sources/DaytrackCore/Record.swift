import Foundation

/// Everything Daytrack keeps. Stored and copied through `CopyFileCodec`.
public struct Record: Hashable, Sendable {
    public var settings: Settings
    public var trackers: [Tracker]
    public var revisions: [ScaleRevision]
    public var entries: [DayKey: DayEntry]

    public init(settings: Settings = Settings(), trackers: [Tracker] = [], revisions: [ScaleRevision] = [], entries: [DayKey: DayEntry] = [:]) {
        self.settings = settings
        self.trackers = trackers
        self.revisions = revisions
        self.entries = entries
    }
}

public struct Settings: Hashable, Codable, Sendable {
    /// An absolute local time of day (Q10).
    public struct ReminderTime: Hashable, Codable, Sendable {
        public var hour: Int
        public var minute: Int

        public init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
    }

    public var lockHour: Int
    public var closedThrough: DayKey?
    /// nil = no reminder.
    public var reminderAt: ReminderTime?

    public init(lockHour: Int = 23, closedThrough: DayKey? = nil, reminderAt: ReminderTime? = ReminderTime(hour: 21, minute: 30)) {
        self.lockHour = lockHour
        self.closedThrough = closedThrough
        self.reminderAt = reminderAt
    }
}
