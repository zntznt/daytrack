import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@Suite struct LaunchOverridesTests {
    @Test func parsesNowAndTimeZone() {
        let o = LaunchOverrides(arguments: ["Daytrack", "-uiTestNow", "2027-03-10T10:00:00", "-uiTestTZ", "America/New_York",
                                            "-uiTestStore", "memory", "-uiTestSeed", "fortyDays", "-uiTestScreen", "settings"])
        #expect(o.timeZone?.identifier == "America/New_York")
        #expect(o.now == ISO8601DateFormatter().date(from: "2027-03-10T15:00:00Z"))
        #expect(o.store == "memory" && o.seed == "fortyDays" && o.screen == "settings" && o.lockHour == nil)
    }

    @Test func lockHourOverrideAppliesToSeed() throws {
        let env = try LaunchOverrides(arguments: ["-uiTestStore", "memory", "-uiTestSeed", "threeTrackersEmpty", "-uiTestLockHour", "4"]).environment()
        guard case .loaded(let record) = try env.records.load() else { Issue.record("expected the seeded record"); return }
        #expect(record.settings.lockHour == 4 && record.trackers.count == 3)
    }

    @Test func offsetClockAdvancesFromGivenInstant() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let clock = OffsetClock(start: start)
        let first = clock.now
        Thread.sleep(forTimeInterval: 0.05)
        #expect(first >= start && first < start.addingTimeInterval(5) && clock.now > first)
    }

    @Test func fixturesAreDeterministic() {
        let today = DayKey("2027-03-10")!
        let tz = TimeZone(identifier: "America/New_York")!
        for name in Fixtures.names {
            let a = Fixtures.make(name, today: today, tz: tz)
            let b = Fixtures.make(name, today: today, tz: tz)
            #expect(a.0 == b.0 && a.1 == b.1, "\(name)")
        }
        let blank = Fixtures.make("yesterdayWhollyBlank", today: today, tz: tz)
        #expect(blank.0.entries[today.adding(days: -1)] == nil)
        #expect(blank.0.settings.reminderAt == Settings.ReminderTime(hour: 21, minute: 30))
        #expect(blank.1.remindersScheduledThrough == today.adding(days: 13))
        #expect(Fixtures.make("allArchived", today: today, tz: tz).0.trackers.allSatisfy { $0.isArchived })
        #expect(Fixtures.make("ninetyDaysWithRevision", today: today, tz: tz).0.revisions.count == 1)
    }
}
