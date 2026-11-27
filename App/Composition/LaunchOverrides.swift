#if DEBUG
import DaytrackCore
import DaytrackStorage
import Foundation

/// DEBUG launch arguments (docs/plan/README.md §6).
struct LaunchOverrides {
    var now: Date?
    var timeZone: TimeZone?
    /// "memory", or a folder name under tmp/.
    var store: String?
    var seed: String?
    var lockHour: Int?
    var screen: String?
    /// A path, absolute or under tmp/.
    var exportTo: String?

    init(arguments: [String]) {
        func value(_ flag: String) -> String? {
            guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        if let id = value("-uiTestTZ") {
            guard let tz = TimeZone(identifier: id) else { preconditionFailure("unknown -uiTestTZ \(id)") }
            timeZone = tz
        }
        if let text = value("-uiTestNow") {
            let f = DateFormatter()
            (f.locale, f.timeZone, f.dateFormat) = (Locale(identifier: "en_US_POSIX"), timeZone ?? .autoupdatingCurrent, "yyyy-MM-dd'T'HH:mm:ss")
            guard let date = f.date(from: text) else { preconditionFailure("-uiTestNow wants yyyy-MM-ddTHH:mm:ss, got \(text)") }
            now = date
        }
        if let text = value("-uiTestLockHour") {
            guard let hour = Int(text), (0...23).contains(hour) else { preconditionFailure("-uiTestLockHour wants 0-23, got \(text)") }
            lockHour = hour
        }
        store = value("-uiTestStore")
        seed = value("-uiTestSeed")
        screen = value("-uiTestScreen")
        exportTo = value("-uiTestExportTo")
    }

    /// The live environment with each given override applied. A seed only fills an empty store, so relaunches keep their files.
    func environment() throws -> AppEnvironment {
        var env = AppEnvironment.live()
        env.screen = screen
        env.exportTo = exportTo.map { URL(fileURLWithPath: $0, isDirectory: true, relativeTo: FileManager.default.temporaryDirectory) }
        if let timeZone { env.timeZone = timeZone }
        if let now { env.clock = OffsetClock(start: now) }
        switch store {
        case nil: break
        case "memory":
            env.records = InMemoryRecordStore()
            env.deviceState = InMemoryDeviceStateStore()
        case let name?:
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: true)
            env.records = FileRecordStore(directory: directory)
            env.deviceState = FileDeviceStateStore(directory: directory)
        }
        if let seed, case .empty = try env.records.load() {
            let today = LocalCalendar(timeZone: env.timeZone).dayKey(for: env.clock.now)
            var (record, device) = Fixtures.make(seed, today: today, tz: env.timeZone)
            if let lockHour { record.settings.lockHour = lockHour }
            try env.records.save(record)
            try env.deviceState.save(device)
        }
        return env
    }
}

/// Starts at `start`, then runs at real speed.
struct OffsetClock: Clock {
    let start: Date
    let launchedAt = Date()

    var now: Date { start.addingTimeInterval(Date().timeIntervalSince(launchedAt)) }
}
#endif
