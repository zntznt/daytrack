import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor @Suite struct OnboardingTests {
    @Test func startCreatesOnlyPickedWithCreatedAtToday() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // 04:30 UTC is 00:30 on 22 July in New York.
        let now = ISO8601DateFormatter().date(from: "2027-07-22T04:30:00Z")!
        let app = AppState(AppEnvironment(records: InMemoryRecordStore(), deviceState: InMemoryDeviceStateStore(),
                                          clock: FixedClock(now), timeZone: tz))
        var picks = StarterPicks()
        picks.toggle(StarterCatalog.all[7])
        picks.toggle(StarterCatalog.all[0])
        try app.trackers.startBoard(picked: picks.picked)

        let trackers = app.store.record.trackers
        #expect(trackers.map(\.name) == ["Meds taken", "Sleep"])
        #expect(trackers.allSatisfy { $0.createdAt == DayKey("2027-07-22")! && $0.archivedRanges.isEmpty })
        #expect(app.route == .tabs)
    }

    @Test func picksStayBetweenOneAndEight() {
        var picks = StarterPicks()
        #expect(!picks.canStart && picks.reason == StarterPicks.noPickReason)
        for starter in StarterCatalog.all.prefix(9) { picks.toggle(starter) }
        #expect(picks.picked == Array(StarterCatalog.all.prefix(8)))
        #expect(picks.reason == Roster.fullRefusal)
        picks.toggle(StarterCatalog.all[0])
        #expect(picks.picked.count == 7 && picks.reason == nil && picks.canStart)
    }
}
