import DaytrackCore
import Foundation
import Testing
import UserNotifications
@testable import Daytrack

/// Counts permission requests on top of the fake centre.
private final class CountingClient: NotificationCenterClient, @unchecked Sendable {
    let base: FakeNotificationCenterClient
    private(set) var requests = 0
    init(grants: Bool) { base = FakeNotificationCenterClient(grants: grants) }

    func pendingIdentifiers() async -> [String] { await base.pendingIdentifiers() }
    func add(_ request: UNNotificationRequest) async throws { try await base.add(request) }
    func removePending(_ identifiers: [String]) { base.removePending(identifiers) }
    func setCategories(_ categories: Set<UNNotificationCategory>) { base.setCategories(categories) }
    func authorizationStatus() async -> UNAuthorizationStatus { await base.authorizationStatus() }
    func requestAuthorization() async throws -> Bool { requests += 1; return try await base.requestAuthorization() }
}

@MainActor @Suite struct ReminderSettingsModelTests {
    let tz = TimeZone(identifier: "UTC")!
    let today = DayKey("2027-07-22")!
    let clock = FixedClock(ISO8601DateFormatter().date(from: "2027-07-22T10:00:00Z")!)

    private func make(grants: Bool) -> (ReminderSettingsModel, CountingClient, NotificationScheduler, Recorder) {
        let client = CountingClient(grants: grants)
        let deviceState = InMemoryDeviceStateStore()
        let scheduler = NotificationScheduler(client: client, deviceState: deviceState, tz: tz)
        let sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: today.adding(days: -10))
        let recorder = Recorder(record: Record(trackers: [sleep]), store: InMemoryRecordStore(), clock: clock, widget: NoWidget(),
                                reminders: scheduler, tz: tz)
        let model = ReminderSettingsModel(settings: SettingsService(recorder: recorder, deviceState: deviceState),
                                          asker: PermissionAsker(client: client), record: { recorder.record }, clock: clock, tz: tz)
        return (model, client, scheduler, recorder)
    }

    @Test func toggleOnSchedulesWithChosenTime() async throws {
        let (model, client, scheduler, recorder) = make(grants: true)
        #expect(!model.isOn)
        // Off, the default 21:30 is in the record but nothing was asked; pick 20:15 first.
        model.setTime(Settings.ReminderTime(hour: 20, minute: 15))
        await model.setOn(true)
        await scheduler.settled()
        #expect(model.isOn)
        #expect(recorder.record.settings.reminderAt == Settings.ReminderTime(hour: 20, minute: 15))
        #expect(model.scheduledLine == "scheduled for 20:15; delivery can still move it")
        #expect(model.remindTitle == "Remind me at 20:15")
        let first = try #require(client.base.requests.first?.trigger as? UNCalendarNotificationTrigger)
        #expect(first.dateComponents.hour == 20 && first.dateComponents.minute == 15)
    }

    @Test func permissionAskedOnlyOnce() async {
        let (model, client, _, _) = make(grants: true)
        await model.refresh()
        #expect(client.requests == 0)
        await model.setOn(true)
        await model.setOn(false)
        #expect(!model.isOn)
        await model.setOn(true)
        #expect(client.requests == 1)
        #expect(model.isOn)
    }

    @Test func deniedShowsSystemSettingsLineNoReprompt() async {
        let (model, client, _, _) = make(grants: false)
        await model.setOn(true)
        #expect(model.isDenied && !model.isOn)
        #expect(ReminderSettingsModel.deniedLine == "Notifications are off for Daytrack in system settings")
        await model.setOn(true)
        #expect(client.requests == 1)
        #expect(!model.isOn)
    }
}
