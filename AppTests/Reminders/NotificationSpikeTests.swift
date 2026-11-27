import Foundation
import Testing
import UserNotifications

/// Q10 amendment 2, against the real centre (docs/spikes/notifications.md). Uses its own `spike-` ids.
/// The iOS 27.2 simulator refuses `add` to a hosted test (UNErrorDomain 2003), so these run only where Daytrack
/// already has full authorization: on a device, at M3.15.
@Suite(.serialized, .enabled("needs full notification authorization") {
    await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .authorized
})
struct NotificationSpikeTests {
    let center = UNUserNotificationCenter.current()

    private func requests(_ prefix: String, hour: Int) -> [UNNotificationRequest] {
        let cal = Calendar(identifier: .gregorian)
        return (1...14).map { offset in
            let d = cal.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(Double(offset) * 86_400))
            let fire = DateComponents(year: d.year, month: d.month, day: d.day, hour: hour, minute: 30)
            let content = UNMutableNotificationContent()
            content.title = "Spike"
            return UNNotificationRequest(identifier: "\(prefix)\(offset)", content: content,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: fire, repeats: false))
        }
    }

    private func spikePending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests().filter { $0.identifier.hasPrefix("spike-") }
    }

    private func clear() async {
        center.removePendingNotificationRequests(withIdentifiers: await spikePending().map(\.identifier))
    }

    @Test func realCenterHoldsFourteenFloatingTriggers() async throws {
        await clear()
        for r in requests("spike-", hour: 21) { try await center.add(r) }
        let pending = await spikePending()
        #expect(pending.count == 14)
        #expect(pending.allSatisfy { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents.timeZone == nil })
        await clear()
    }

    @Test func replacingKeepsPendingAtOrBelow64() async throws {
        await clear()
        // Five replans: same ids overwritten, then a fresh set after removing the old.
        for round in 0..<5 {
            if round.isMultiple(of: 2) { await clear() }
            for r in requests("spike-", hour: 20 + round % 3) { try await center.add(r) }
            let all = await center.pendingNotificationRequests()
            #expect(all.count <= 64)
            #expect(await spikePending().count == 14)
        }
        await clear()
    }
}
