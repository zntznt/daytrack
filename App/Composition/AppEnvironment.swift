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
    var widget: WidgetPublishing = NoWidget()
    /// Set only by `-uiTestScreen` in DEBUG.
    var screen: String?

    /// File stores in `Application Support/Daytrack/`, the system clock and zone.
    static func live() -> AppEnvironment {
        let directory = URL.applicationSupportDirectory.appendingPathComponent("Daytrack", isDirectory: true)
        return AppEnvironment(records: FileRecordStore(directory: directory), deviceState: FileDeviceStateStore(directory: directory),
                              clock: SystemClock(), timeZone: .autoupdatingCurrent)
    }

    static func launch() -> AppEnvironment {
        #if DEBUG
        return try! LaunchOverrides(arguments: ProcessInfo.processInfo.arguments).environment()
        #else
        return live()
        #endif
    }
}

struct SystemClock: Clock { var now: Date { Date() } }

/// Replaced in M3.13.
struct NoReminders: ReminderScheduling { func replan(record: Record, now: Date) {}; func removeAll() {} }

/// Replaced in M8.03.
struct NoWidget: WidgetPublishing { func publish(record: Record, now: Date) {} }
