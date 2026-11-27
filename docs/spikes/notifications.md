# Spike: iOS pending notification limits (M3.13)

**Status: not verified; run on device at M3.15.** Nothing here is verified on simulator or device yet.

Questions (decisions Q10 amendment 2 and "Unverified"):
1. Do 14 non-repeating `UNCalendarNotificationTrigger`s with `dateComponents.timeZone == nil` all appear in `pendingNotificationRequests()`?
2. Does replacing them keep the pending count at or below 64?

Test: `AppTests/Reminders/NotificationSpikeTests.swift` (`realCenterHoldsFourteenFloatingTriggers`, `replacingKeepsPendingAtOrBelow64`).

Simulator, 2026-11-27 (iPhone 18 Pro, iOS 27.2, Xcode 27.2):
- An app-hosted test cannot add to the real centre. `add` throws UNErrorDomain 2003 "Source is not authorized".
- Provisional authorization (status 3) does not help; `add` still throws 2003.
- `xcrun simctl privacy` has no notifications service, so the runner cannot grant it.

So both tests are disabled unless authorization is `.authorized`, and run on a device where Daytrack was allowed.
The scheduler (M3.13 step 2) is tested against `FakeNotificationCenterClient` meanwhile.
