import DaytrackCore
import Foundation
import UserNotifications

/// Turns each `ReminderPlan` into pending `reminder-YYYY-MM-DD` requests (decisions Q10 and its amendment 2).
/// Replans run one after another, so a slow older one never re-adds a day a newer one dropped.
final class NotificationScheduler: ReminderScheduling, @unchecked Sendable {
    static let prefix = "reminder-"
    static let category = "daily"
    static let openAction = "open"
    static let skipRestAction = "skipRest"
    static let dayKey = "day"

    private let client: NotificationCenterClient
    private let deviceState: DeviceStateStore
    private let tz: TimeZone
    private let lock = NSLock()
    private var last: Task<Void, Never>?

    init(client: NotificationCenterClient, deviceState: DeviceStateStore, tz: TimeZone) {
        (self.client, self.deviceState, self.tz) = (client, deviceState, tz)
        client.setCategories([Self.dailyCategory])
    }

    /// The fire is at 21:30 on its own day, so the label reads "today" (Q4 wording).
    static var dailyCategory: UNNotificationCategory {
        UNNotificationCategory(identifier: category, actions: [
            UNNotificationAction(identifier: openAction, title: "Open", options: [.foreground]),
            UNNotificationAction(identifier: skipRestAction, title: Copy.skipRest(dayLabel: "today"), options: []),
        ], intentIdentifiers: [])
    }

    func replan(record: Record, now: Date) {
        let plan = ReminderPlan.make(reminderAt: record.settings.reminderAt, now: now, record: record, tz: tz)
        // M8.01 reads this; a failed save only loses that hint, never a value.
        if var state = try? deviceState.load() {
            state.remindersScheduledThrough = plan.last?.day
            try? deviceState.save(state)
        }
        let requests = plan.map(Self.request)
        enqueue { client in
            await Self.removeReminders(client)
            // Unauthorized, `add` throws; nothing to do until permission is given (M3.14).
            for r in requests { try? await client.add(r) }
        }
    }

    func removeAll() { enqueue { await Self.removeReminders($0) } }

    /// Waits for every replan so far. For tests.
    func settled() async { await lock.withLock { last }?.value }

    private func enqueue(_ work: @escaping @Sendable (NotificationCenterClient) async -> Void) {
        lock.withLock {
            let previous = last
            last = Task { [client] in
                await previous?.value
                await work(client)
            }
        }
    }

    private static func removeReminders(_ client: NotificationCenterClient) async {
        client.removePending(await client.pendingIdentifiers().filter { $0.hasPrefix(prefix) })
    }

    private static func request(_ item: ReminderPlan.Item) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Daily reminder"
        content.categoryIdentifier = category
        content.userInfo = [dayKey: item.day.isoString]
        // `fire.timeZone` is nil: a floating local time that follows the phone's zone.
        let trigger = UNCalendarNotificationTrigger(dateMatching: item.fire, repeats: false)
        return UNNotificationRequest(identifier: prefix + item.day.isoString, content: content, trigger: trigger)
    }
}
