import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor
private func state(_ records: RecordStore) -> AppState {
    AppState(AppEnvironment(records: records, deviceState: InMemoryDeviceStateStore(),
                            clock: FixedClock(Date(timeIntervalSince1970: 1_800_000_000)), timeZone: TimeZone(identifier: "UTC")!))
}

/// The real file store over a record.json that cannot be decoded, in a fresh tmp/ folder.
private func unreadableStore() throws -> RecordStore {
    let name = "RootRoutingTests-\(UUID().uuidString)"
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try Data("not a record".utf8).write(to: dir.appendingPathComponent("record.json"))
    return try LaunchOverrides(arguments: ["-uiTestStore", name]).environment().records
}

@MainActor @Suite struct RootRoutingTests {
    @Test func routesToOnboardingWhenNoTrackers() {
        #expect(state(InMemoryRecordStore()).route == .onboarding)
    }

    @Test func routesToTabsWhenTrackersExist() throws {
        let app = state(InMemoryRecordStore())
        try app.trackers.startBoard(picked: [StarterCatalog.all[0]])
        #expect(app.route == .tabs)

        let seeded = Fixtures.make("threeTrackersEmpty", today: DayKey("2027-03-10")!, tz: .gmt).0
        #expect(state(InMemoryRecordStore(seeded)).route == .tabs)
    }

    @Test func unreadableStoreRoutesToReadOnlyState() throws {
        guard case .unreadable(let keptAt) = state(try unreadableStore()).route else { Issue.record("expected the unreadable route"); return }
        #expect(keptAt.lastPathComponent.hasPrefix("record-unreadable-") && FileManager.default.fileExists(atPath: keptAt.path))
    }

    @Test func unreadableScreenContinueLeadsToOnboarding() throws {
        let app = state(try unreadableStore())
        app.continueFromUnreadable()
        #expect(app.route == .onboarding)
    }
}
