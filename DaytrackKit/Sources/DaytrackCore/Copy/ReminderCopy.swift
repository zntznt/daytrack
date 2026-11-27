import Foundation

extension Copy {
    // MARK: Reminder (decisions Q10)

    /// "scheduled for 21:30; delivery can still move it".
    public static func reminderScheduled(_ at: Settings.ReminderTime) -> String {
        "scheduled for \(String(format: "%02d:%02d", at.hour, at.minute)); delivery can still move it"
    }

    /// The 14-day limit (Q10 amendment 2): plain, no re-fire promise.
    public static let reminderHorizon = "Reminders are set 14 days ahead. If Daytrack is not opened for that long, they stop."
}
