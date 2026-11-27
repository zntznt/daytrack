import UserNotifications

/// The one permission Daytrack asks for, and only on an explicit tap (decisions Q10).
/// It asks while the answer is undetermined; after that the first answer stands, so a refusal is never re-prompted.
struct PermissionAsker {
    let client: NotificationCenterClient

    func allowed() async -> Bool {
        switch await client.authorizationStatus() {
        case .notDetermined: (try? await client.requestAuthorization()) ?? false
        case .denied: false
        default: true
        }
    }
}
