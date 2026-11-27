import Foundation
import Testing
@testable import DaytrackCore

private let start = DayKey("2027-01-01")!

private func trackers(active: Int, archived: Int = 0) -> [Tracker] {
    (0..<active).map { Tracker(name: "A\($0)", symbol: "circle", type: .numeric, createdAt: start) }
        + (0..<archived).map {
            Tracker(name: "Z\($0)", symbol: "circle", type: .binary, createdAt: start,
                    archivedRanges: [.init(from: start.adding(days: 1))])
        }
}

@Suite struct RosterTests {
    @Test func ninthActiveTrackerRefusedWithExactCopy() {
        #expect(Roster.canActivate(alongside: trackers(active: 7)) == .allowed)
        #expect(Roster.canActivate(alongside: trackers(active: 8))
                == .refused("Eight fit on one board. Archive one to make room."))
    }

    @Test func archiveIsUnlimited() {
        #expect(Roster.canActivate(alongside: trackers(active: 7, archived: 50)) == .allowed)
        #expect(trackers(active: 0, archived: 50).allSatisfy { $0.isArchived })
    }
}
