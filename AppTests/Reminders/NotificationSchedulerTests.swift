import DaytrackCore
import Foundation
import Testing
import UserNotifications
@testable import Daytrack

@MainActor @Suite struct NotificationSchedulerTests {
    let tz = TimeZone(identifier: "UTC")!
    let today = DayKey("2027-07-22")!
    let clock = FixedClock(ISO8601DateFormatter().date(from: "2027-07-22T10:00:00Z")!)
    let client = FakeNotificationCenterClient(grants: true)
    let deviceState = InMemoryDeviceStateStore()
    let store = InMemoryRecordStore()
    let sleep: Tracker, mood: Tracker

    init() {
        sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: today.adding(days: -10))
        mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: today.adding(days: -10))
    }

    private var scheduler: NotificationScheduler { NotificationScheduler(client: client, deviceState: deviceState, tz: tz) }

    private func recorder(_ scheduler: NotificationScheduler, record: Record? = nil) -> Recorder {
        Recorder(record: record ?? Record(trackers: [sleep, mood]), store: store, clock: clock, widget: NoWidget(), reminders: scheduler, tz: tz)
    }

    private func handler(_ recorder: Recorder) -> NotificationActionHandler {
        NotificationActionHandler(recorder: recorder, clock: clock, tz: tz)
    }

    @Test func schedulesFourteenRequestsFromPlan() async throws {
        let scheduler = scheduler
        // A stale request from an earlier plan is replaced; other ids are left alone.
        try await client.add(UNNotificationRequest(identifier: "reminder-2027-07-01", content: UNNotificationContent(), trigger: nil))
        try await client.add(UNNotificationRequest(identifier: "other", content: UNNotificationContent(), trigger: nil))
        scheduler.replan(record: Record(trackers: [sleep]), now: clock.now)
        await scheduler.settled()
        let reminders = client.requests.filter { $0.identifier.hasPrefix("reminder-") }
        #expect(reminders.map(\.identifier) == (0..<14).map { "reminder-" + today.adding(days: $0).isoString })
        #expect(client.requests.contains { $0.identifier == "other" })
        let first = try #require(reminders.first)
        #expect(first.content.title == "Daily reminder")
        #expect(first.content.categoryIdentifier == "daily")
        #expect(first.content.userInfo["day"] as? String == "2027-07-22")
        let trigger = try #require(first.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats && trigger.dateComponents.timeZone == nil)
        #expect(trigger.dateComponents.hour == 21 && trigger.dateComponents.minute == 30 && trigger.dateComponents.day == 22)
    }

    @Test func todayRemovedWhenBoardComplete() async throws {
        let scheduler = scheduler
        let recorder = recorder(scheduler)
        try recorder.write(6, to: sleep.id, on: today)
        await scheduler.settled()
        #expect(client.requests.first?.identifier == "reminder-2027-07-22")
        // The last blank written: every write replans.
        try recorder.write(4, to: mood.id, on: today)
        await scheduler.settled()
        #expect(client.requests.count == 13)
        #expect(client.requests.first?.identifier == "reminder-2027-07-23")
    }

    @Test func categoryHasOpenAndSkipRestActions() throws {
        _ = scheduler
        let daily = try #require(client.categories.first { $0.identifier == "daily" })
        #expect(daily.actions.map(\.identifier) == ["open", "skipRest"])
        #expect(daily.actions.map(\.title) == ["Open", "Skip the rest of today"])
        #expect(daily.actions[0].options.contains(.foreground))
        #expect(!daily.actions[1].options.contains(.foreground))
    }

    @Test func skipActionForClosedDayWritesNothing() throws {
        let recorder = recorder(scheduler)
        let closed = today.adding(days: -2)
        handler(recorder).handle(action: "skipRest", day: closed)
        #expect(recorder.record.entries[closed] == nil)
        #expect(try store.load() == .empty)
    }

    @Test func skipActionWritesSkipIntoBlanksOnly() throws {
        let recorder = recorder(scheduler)
        try recorder.write(6, to: sleep.id, on: today)
        handler(recorder).handle(action: "skipRest", day: today)
        #expect(recorder.record.entries[today]?.values == [sleep.id: .set(6), mood.id: .skip])
    }

    @Test func replanRecordsScheduledThrough() throws {
        let scheduler = scheduler
        scheduler.replan(record: Record(trackers: [sleep]), now: clock.now)
        #expect(try deviceState.load().remindersScheduledThrough == today.adding(days: 13))
        scheduler.replan(record: Record(settings: Settings(reminderAt: nil), trackers: [sleep]), now: clock.now)
        #expect(try deviceState.load().remindersScheduledThrough == nil)
    }

    @Test func openActionForOpenYesterdayRoutesToAmend() {
        let actions = handler(recorder(scheduler))
        actions.handle(action: "open", day: today.adding(days: -1))
        #expect(actions.route == .amend && actions.opens == 1)
        actions.handle(action: "open", day: today)
        #expect(actions.route == .today && actions.opens == 2)
        // Two days back is closed: Today, not a read-only board.
        actions.handle(action: "open", day: today.adding(days: -2))
        #expect(actions.route == .today)
    }
}
