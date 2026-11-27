import Foundation
import Testing
@testable import DaytrackCore

private let newYork = TimeZone(identifier: "America/New_York")!
private let nine30 = Settings.ReminderTime(hour: 21, minute: 30)

private func day(_ s: String) -> DayKey { DayKey(s)! }

private func at(_ d: String, _ hour: Int, _ minute: Int = 0) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = newYork
    let k = day(d)
    return cal.date(from: DateComponents(year: k.year, month: k.month, day: k.day, hour: hour, minute: minute))!
}

private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-07-01"))
private let mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: day("2027-07-01"))

private func record(_ trackers: [Tracker] = [sleep, mood], today values: [UUID: DayValue] = [:]) -> Record {
    let entry = DayEntry(date: day("2027-07-22"), values: values, firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0)
    return Record(trackers: trackers, entries: values.isEmpty ? [:] : [day("2027-07-22"): entry])
}

private func plan(_ r: Record = record(), now: Date = at("2027-07-22", 12), reminderAt: Settings.ReminderTime? = nine30) -> [ReminderPlan.Item] {
    ReminderPlan.make(reminderAt: reminderAt, now: now, record: r, tz: newYork, horizonDays: 14)
}

@Suite struct ReminderPlanTests {
    @Test func schedulesFourteenDaysAhead() {
        let items = plan()
        #expect(items.count == 14)
        #expect(items.first?.day == day("2027-07-22"))
        #expect(items.last?.day == day("2027-08-04"))
        #expect(Set(items.map(\.day)).count == 14)
    }

    @Test func fireComponentsHaveNoTimeZone() {
        for item in plan() {
            #expect(item.fire.timeZone == nil)
            #expect(item.fire.calendar == nil)
            #expect(item.fire == DateComponents(year: item.day.year, month: item.day.month, day: item.day.day, hour: 21, minute: 30))
        }
    }

    @Test func todayOmittedWhenNoBlanks() {
        let items = plan(record(today: [sleep.id: .set(7), mood.id: .skip]))
        #expect(items.first?.day == day("2027-07-23"))
        #expect(items.count == 13)
        // One blank left keeps today in.
        #expect(plan(record(today: [sleep.id: .set(7)])).first?.day == day("2027-07-22"))
    }

    @Test func todayOmittedWhenTimePassed() {
        #expect(plan(now: at("2027-07-22", 21, 30)).first?.day == day("2027-07-23"))
        #expect(plan(now: at("2027-07-22", 22)).count == 13)
        #expect(plan(now: at("2027-07-22", 21, 29)).first?.day == day("2027-07-22"))
    }

    @Test func noneWhenReminderOff() {
        #expect(plan(reminderAt: nil).isEmpty)
    }

    @Test func noneWhenNoActiveTracker() {
        let archived = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-07-01"),
                               archivedRanges: [.init(from: day("2027-07-10"))])
        #expect(plan(record([archived])).isEmpty)
        #expect(plan(record([])).isEmpty)
    }

    @Test func neverRefiresMissedDay() {
        // Yesterday had blanks and its 21:30 passed unanswered; the plan starts no earlier than today.
        let items = plan(now: at("2027-07-22", 8))
        #expect(items.allSatisfy { $0.day >= day("2027-07-22") })
        #expect(!items.contains { $0.day == day("2027-07-21") })
    }
}
