import DaytrackCore
import Foundation
import Observation
import UserNotifications

/// The reminder's two actions (HANDOFF §8 "Notification actions (native)", decisions Q4).
/// Both are the board's own operations: Open shows a board, Skip goes through `Recorder.skipRest`.
@MainActor @Observable
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    enum Route: Hashable { case today, amend }

    @ObservationIgnored private let recorder: Recorder
    @ObservationIgnored private let clock: Clock
    @ObservationIgnored private let tz: TimeZone
    /// Bumped on every Open, so the root returns to the Today tab.
    private(set) var opens = 0
    /// `.amend` while yesterday's board is shown for an Open.
    var route: Route?

    init(recorder: Recorder, clock: Clock, tz: TimeZone) {
        (self.recorder, self.clock, self.tz) = (recorder, clock, tz)
    }

    func handle(action: String, day: DayKey?) {
        switch action {
        case NotificationScheduler.skipRestAction:
            // A closed day refuses the write in the Recorder, so nothing is saved.
            if let day { try? recorder.skipRest(day: day) }
        case NotificationScheduler.openAction, UNNotificationDefaultActionIdentifier:
            route = route(for: day)
            opens += 1
        default: break
        }
    }

    /// Yesterday's board while the notification's day is yesterday and still open; otherwise Today.
    private func route(for day: DayKey?) -> Route {
        try? recorder.refresh()
        let s = recorder.record.settings
        guard let day, case .yesterdayOpen = DayClosing.status(of: day, now: clock.now, lockHour: s.lockHour,
                                                               closedThrough: s.closedThrough, tz: tz) else { return .today }
        return .amend
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        let day = (response.notification.request.content.userInfo[NotificationScheduler.dayKey] as? String).flatMap(DayKey.init)
        await handle(action: action, day: day)
    }
}
