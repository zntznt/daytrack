#if DEBUG
import DaytrackCore
import Foundation

/// Deterministic seed records: the same name, today and zone always give the same record, ids included.
enum Fixtures {
    static let names = ["threeTrackersEmpty", "eightTrackers", "fortyDays", "ninetyDaysWithRevision", "yesterdayWhollyBlank", "allArchived"]

    static func make(_ name: String, today: DayKey, tz: TimeZone) -> (Record, DeviceState) {
        switch name {
        case "threeTrackersEmpty": return (Record(trackers: trackers(3, today)), DeviceState())
        case "eightTrackers": return (Record(trackers: trackers(8, today)), DeviceState())
        case "fortyDays":
            let t = trackers(3, today)
            return (Record(trackers: t, entries: days(40, endingOn: today.adding(days: -1), t, tz)), DeviceState())
        case "ninetyDaysWithRevision":
            // Anxiety (ordinal) is the seventh starter; its words changed 30 days ago.
            let t = trackers(7, today)
            let revision = try! ScaleRevision(tracker: t[6], effectiveFrom: today.adding(days: -30),
                                              previousLabels: ["None", "Slight", "Mild", "Moderate", "Severe"])
            return (Record(trackers: t, revisions: [revision], entries: days(90, endingOn: today.adding(days: -1), t, tz)), DeviceState())
        case "yesterdayWhollyBlank":
            let t = trackers(3, today), settings = Settings(reminderAt: Settings.ReminderTime(hour: 21, minute: 30))
            return (Record(settings: settings, trackers: t, entries: days(10, endingOn: today.adding(days: -2), t, tz)),
                    DeviceState(remindersScheduledThrough: today.adding(days: 13)))
        case "allArchived":
            var t = trackers(3, today)
            for i in t.indices { t[i].archivedRanges = [Tracker.ArchivedRange(from: today.adding(days: -5))] }
            return (Record(trackers: t, entries: days(20, endingOn: today.adding(days: -6), t, tz)), DeviceState())
        default:
            preconditionFailure("unknown fixture \(name)")
        }
    }

    /// The first `count` starters, made 100 days ago with fixed ids.
    private static func trackers(_ count: Int, _ today: DayKey) -> [Tracker] {
        StarterCatalog.all.prefix(count).enumerated().map { i, s in
            Tracker(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", i + 1))!, name: s.name,
                    symbol: s.symbol, type: s.type, createdAt: today.adding(days: -100))
        }
    }

    /// `count` days ending on `end`, written at 20:00 local. Some values are skipped, some left blank.
    private static func days(_ count: Int, endingOn end: DayKey, _ trackers: [Tracker], _ tz: TimeZone) -> [DayKey: DayEntry] {
        let cal = LocalCalendar(timeZone: tz)
        var entries: [DayKey: DayEntry] = [:]
        for d in 0..<count {
            let day = end.adding(days: d - count + 1)
            var values: [UUID: DayValue] = [:]
            for (i, t) in trackers.enumerated() where (d + i) % 5 != 4 {
                values[t.id] = (d + 2 * i) % 11 == 10 ? .skip : .set(t.type.value(forIndex: (d * 7 + i * 3) % t.type.stops))
            }
            let at = cal.startOfDay(day).addingTimeInterval(20 * 3600)
            entries[day] = DayEntry(date: day, values: values, firstWrittenAt: at, lastWrittenAt: at, tzOffsetAtWrite: tz.secondsFromGMT(for: at))
        }
        return entries
    }
}
#endif
