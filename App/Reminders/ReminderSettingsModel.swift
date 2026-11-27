import DaytrackCore
import Foundation
import Observation
import UserNotifications

/// The reminder toggle and time (decisions Q10). On means a time is set and the phone allows notifications.
/// Permission is asked only from `setOn(true)`, on a tap in Settings or the day-one-written screen, and only while
/// undetermined: the first answer stands, so a refusal is never re-prompted.
@MainActor @Observable
final class ReminderSettingsModel {
    static let deniedLine = "Notifications are off for Daytrack in system settings"

    @ObservationIgnored private let settings: SettingsService
    @ObservationIgnored private let client: NotificationCenterClient
    @ObservationIgnored private let record: () -> Record
    @ObservationIgnored private let clock: Clock
    @ObservationIgnored private let tz: TimeZone
    private(set) var status = UNAuthorizationStatus.notDetermined
    /// The time while the reminder is off, so turning it on keeps the pick.
    private var offTime = Settings.ReminderTime(hour: 21, minute: 30)

    init(settings: SettingsService, client: NotificationCenterClient, record: @escaping () -> Record, clock: Clock, tz: TimeZone) {
        (self.settings, self.client, self.record, self.clock, self.tz) = (settings, client, record, clock, tz)
    }

    var isOn: Bool { record().settings.reminderAt != nil && isAllowed }
    var isDenied: Bool { status == .denied }
    var time: Settings.ReminderTime { record().settings.reminderAt ?? offTime }
    /// The day-one button: "Remind me at 20:15".
    /// shortcut: built here because DaytrackCore/Copy is outside M3.14's scope; move it to Copy.
    var remindTitle: String { String(format: "Remind me at %02d:%02d", time.hour, time.minute) }
    var scheduledLine: String { Copy.reminderScheduled(time) }

    /// Today has no blanks, so tonight's reminder is already cancelled (HANDOFF §9).
    var nothingTonight: Bool {
        let r = record(), today = LocalCalendar(timeZone: tz).dayKey(for: clock.now)
        return RowCounts(entry: r.entries[today], day: today, trackers: r.trackers).blank == 0
    }

    private var isAllowed: Bool { ![.notDetermined, .denied].contains(status) }

    func refresh() async { status = await client.authorizationStatus() }

    func setOn(_ on: Bool) async {
        if !on { offTime = time; try? settings.setReminderAt(nil); return }
        await refresh()
        if status == .notDetermined { _ = try? await client.requestAuthorization() }
        await refresh()
        if isAllowed { try? settings.setReminderAt(time) }
    }

    func setTime(_ next: Settings.ReminderTime) {
        if record().settings.reminderAt == nil { offTime = next } else { try? settings.setReminderAt(next) }
    }
}
