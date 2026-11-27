import Foundation
import UserNotifications

/// The part of `UNUserNotificationCenter` Daytrack uses, so tests and UI tests can run without the real centre.
protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]
    func add(_ request: UNNotificationRequest) async throws
    func removePending(_ identifiers: [String])
    func setCategories(_ categories: Set<UNNotificationCategory>)
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
}

struct UserNotificationCenterClient: NotificationCenterClient {
    private var center: UNUserNotificationCenter { .current() }

    func pendingIdentifiers() async -> [String] { await center.pendingNotificationRequests().map(\.identifier) }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func removePending(_ identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
    func setCategories(_ categories: Set<UNNotificationCategory>) { center.setNotificationCategories(categories) }
    func authorizationStatus() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }
    func requestAuthorization() async throws -> Bool { try await center.requestAuthorization(options: [.alert, .sound]) }
}

#if DEBUG
/// `-uiTestNotifications fake` grants, `fakeDeny` denies (docs/plan/README.md §6). Keeps requests in memory.
final class FakeNotificationCenterClient: NotificationCenterClient, @unchecked Sendable {
    private let lock = NSLock()
    private let grants: Bool
    private var status = UNAuthorizationStatus.notDetermined
    private var pending: [String: UNNotificationRequest] = [:]
    private(set) var categories: Set<UNNotificationCategory> = []

    init(grants: Bool) { self.grants = grants }

    /// Pending requests, sorted by identifier.
    var requests: [UNNotificationRequest] { lock.withLock { pending.values.sorted { $0.identifier < $1.identifier } } }

    func pendingIdentifiers() async -> [String] { lock.withLock { Array(pending.keys) } }
    func add(_ request: UNNotificationRequest) async throws { lock.withLock { pending[request.identifier] = request } }
    func removePending(_ identifiers: [String]) { lock.withLock { identifiers.forEach { pending[$0] = nil } } }
    func setCategories(_ categories: Set<UNNotificationCategory>) { lock.withLock { self.categories = categories } }
    func authorizationStatus() async -> UNAuthorizationStatus { lock.withLock { status } }

    func requestAuthorization() async throws -> Bool {
        lock.withLock {
            // Asked once: a second request returns the first answer, like the system.
            if status == .notDetermined { status = grants ? .authorized : .denied }
            return status == .authorized
        }
    }
}
#endif
