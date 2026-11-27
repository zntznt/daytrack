import DaytrackCore
import DaytrackStorage
import Foundation

/// The only place adapters are wired.
struct AppEnvironment {
    var records: RecordStore
    var deviceState: DeviceStateStore
    var clock: Clock
    var timeZone: TimeZone
    var reminders: ReminderScheduling = NoReminders()
    /// The centre the reminders and the permission prompt (M3.14) go through.
    var notifications: NotificationCenterClient = UserNotificationCenterClient()
    var widget: WidgetPublishing = NoWidget()
    /// Set only by `-uiTestScreen` in DEBUG.
    var screen: String?
    /// Set only by `-uiTestExportTo` in DEBUG: a full copy is written here instead of through `.fileExporter`.
    var exportTo: URL?

    /// Export files live here only while their sheet is open (Q2, HANDOFF §8).
    static let exportsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Exports", isDirectory: true)

    /// File stores in `Application Support/Daytrack/`, the system clock and zone.
    static func live() -> AppEnvironment {
        let directory = URL.applicationSupportDirectory.appendingPathComponent("Daytrack", isDirectory: true)
        var env = AppEnvironment(records: FileRecordStore(directory: directory), deviceState: FileDeviceStateStore(directory: directory),
                                 clock: SystemClock(), timeZone: .autoupdatingCurrent)
        env.wireReminders()
        return env
    }

    /// Call again after replacing `notifications`, `deviceState` or `timeZone`.
    mutating func wireReminders() {
        reminders = NotificationScheduler(client: notifications, deviceState: deviceState, tz: timeZone)
    }

    /// Purges `tmp/Exports/` first, so no copy outlives a crash or a kill with a sheet open.
    static func launch() -> AppEnvironment {
        try? FileManager.default.removeItem(at: exportsDirectory)
        #if DEBUG
        return try! LaunchOverrides(arguments: ProcessInfo.processInfo.arguments).environment()
        #else
        return live()
        #endif
    }
}

struct SystemClock: Clock { var now: Date { Date() } }

/// For tests that do not look at reminders.
struct NoReminders: ReminderScheduling { func replan(record: Record, now: Date) {}; func removeAll() {} }

/// Replaced in M8.03.
struct NoWidget: WidgetPublishing { func publish(record: Record, now: Date) {} }
