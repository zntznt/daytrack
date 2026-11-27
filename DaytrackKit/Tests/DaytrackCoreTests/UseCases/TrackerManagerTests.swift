import Foundation
import Testing
@testable import DaytrackCore

private let d20 = DayKey("2027-07-20")!
private let d21 = DayKey("2027-07-21")!
private let d22 = DayKey("2027-07-22")!

@Suite struct TrackerManagerTests {
    private func manager(_ h: Harness) -> TrackerManager { TrackerManager(recorder: h.recorder, tz: useCaseTZ) }

    private func custom(_ n: Int) -> Tracker {
        Tracker(name: "T\(n)", symbol: "star", type: .numeric, createdAt: DayKey("2027-07-01")!)
    }

    @Test func onboardingCreatesOnlyPicked() throws {
        let h = Harness(Record(), now: useCaseAt("2027-07-22", 10))
        let picked = [StarterCatalog.all[0], StarterCatalog.all[7]]
        try manager(h).startBoard(picked: picked)
        let stored = try #require(h.store.stored)
        #expect(stored.trackers.map(\.name) == ["Sleep", "Meds taken"])
        #expect(stored.trackers.allSatisfy { $0.archivedRanges.isEmpty })
        #expect(throws: TrackerError.refused(Roster.fullRefusal)) {
            try manager(Harness(Record(), now: useCaseAt("2027-07-22", 10))).startBoard(picked: Array(StarterCatalog.all.prefix(9)))
        }
    }

    @Test func createdAtIsToday() throws {
        // 00:30 on the 22nd is still the 22nd locally, even though the 21st is open.
        let h = Harness(now: useCaseAt("2027-07-22", 0, 30))
        let t = try manager(h).createFromCatalog(StarterCatalog.all[1])
        let c = try manager(h).createCustom(name: "Walk", symbol: "figure.walk", type: .binary)
        #expect(t.createdAt == d22)
        #expect(c.createdAt == d22)
        #expect(h.store.stored?.trackers.suffix(2).map(\.id) == [t.id, c.id])
    }

    @Test func ninthCreateRefusedWithReason() throws {
        let h = Harness(Record(trackers: (1...8).map(custom)), now: useCaseAt("2027-07-22", 10))
        let before = h.recorder.record
        #expect(throws: TrackerError.refused("Eight fit on one board. Archive one to make room.")) {
            try manager(h).createCustom(name: "Ninth", symbol: "star", type: .numeric)
        }
        #expect(throws: TrackerError.refused(Roster.fullRefusal)) { try manager(h).createFromCatalog(StarterCatalog.all[0]) }
        #expect(h.recorder.record == before)
        #expect(h.log.events.isEmpty)
    }

    @Test func bringBackRefusedAtEight() throws {
        var old = custom(0)
        old.archivedRanges = [Tracker.ArchivedRange(from: d20)]
        let h = Harness(Record(trackers: (1...8).map(custom) + [old]), now: useCaseAt("2027-07-22", 10))
        #expect(throws: TrackerError.refused(Roster.fullRefusal)) { try manager(h).bringBack(old.id) }
        #expect(h.recorder.record.trackers.last?.isArchived == true)
        try manager(h).archive(h.recorder.record.trackers[0].id)
        try manager(h).bringBack(old.id)
        #expect(h.store.stored?.trackers.last?.isArchived == false)
    }

    @Test func archiveKeepsAllDays() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try h.recorder.write(6, to: useCaseSleep.id, on: d21)
        try h.recorder.write(7, to: useCaseSleep.id, on: d22)
        try manager(h).archive(useCaseSleep.id)
        let stored = try #require(h.store.stored)
        let sleep = try #require(stored.trackers.first { $0.id == useCaseSleep.id })
        #expect(sleep.isArchived)
        #expect(sleep.archivedRanges == [Tracker.ArchivedRange(from: d22)])
        #expect(stored.entries[d21]?.values[useCaseSleep.id] == .set(6))
        #expect(stored.entries[d22]?.values[useCaseSleep.id] == .set(7))
        #expect(ActiveSpan.isActive(sleep, on: d21))
        #expect(!ActiveSpan.isActive(sleep, on: d22))
    }

    @Test func bringBackOpensNewActiveRange() throws {
        var sleep = useCaseSleep
        sleep.archivedRanges = [Tracker.ArchivedRange(from: DayKey("2027-07-10")!)]
        let h = Harness(Record(trackers: [sleep, useCaseMeds]), now: useCaseAt("2027-07-22", 10))
        try manager(h).bringBack(sleep.id)
        let back = try #require(h.store.stored?.trackers.first)
        #expect(back.archivedRanges == [Tracker.ArchivedRange(from: DayKey("2027-07-10")!, to: d21)])
        #expect(!ActiveSpan.isActive(back, on: d21))
        #expect(ActiveSpan.isActive(back, on: d22))
        // Archived and brought back on the same day leaves no range behind.
        try manager(h).archive(sleep.id)
        try manager(h).bringBack(sleep.id)
        #expect(h.store.stored?.trackers.first?.archivedRanges == back.archivedRanges)
    }

    @Test func deletePreviewCountsDaysWithValues() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try h.recorder.write(6, to: useCaseSleep.id, on: d21)
        try h.recorder.skip(useCaseSleep.id, on: d22)
        try h.recorder.write(10, to: useCaseMeds.id, on: d22)
        #expect(manager(h).deletePreview(useCaseSleep.id) == 2)
        #expect(manager(h).deletePreview(useCaseMeds.id) == 1)
    }

    @Test func deleteRemovesValuesAndTracker() throws {
        let rev = try ScaleRevision(tracker: useCaseSleep, effectiveFrom: d20, previousLabels: [], previousAnchors: Tracker.Anchors(low: "awful", high: "great"))
        let h = Harness(Record(trackers: [useCaseSleep, useCaseMeds], revisions: [rev]), now: useCaseAt("2027-07-22", 10))
        try h.recorder.write(6, to: useCaseSleep.id, on: d21)
        try h.recorder.write(10, to: useCaseMeds.id, on: d21)
        try manager(h).delete(useCaseSleep.id)
        let stored = try #require(h.store.stored)
        #expect(stored.trackers.map(\.id) == [useCaseMeds.id])
        #expect(stored.entries.values.allSatisfy { $0.values[useCaseSleep.id] == nil })
        #expect(stored.entries[d21]?.values[useCaseMeds.id] == .set(10))
        #expect(stored.revisions.isEmpty)
    }

    @Test func wordingEditAfterClosedValueAddsRevision() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        // Free while no closed day holds a value.
        try manager(h).editWording(useCaseMeds.id, labels: ["Not yet", "Taken"], anchors: nil)
        #expect(h.store.stored?.revisions.isEmpty == true)
        try h.recorder.write(10, to: useCaseMeds.id, on: d21)
        h.clock.now = useCaseAt("2027-07-23", 10)
        try h.recorder.refresh()
        try manager(h).editWording(useCaseMeds.id, labels: ["No", "Taken"], anchors: nil)
        let stored = try #require(h.store.stored)
        #expect(stored.trackers.first { $0.id == useCaseMeds.id }?.labels == ["No", "Taken"])
        #expect(stored.revisions.count == 1)
        #expect(stored.revisions.first?.effectiveFrom == DayKey("2027-07-23"))
        #expect(stored.revisions.first?.previousLabels == ["Not yet", "Taken"])
        #expect(throws: WordingError.stopCountIsFixed) { try manager(h).editWording(useCaseMeds.id, labels: ["Yes"], anchors: nil) }
    }

    @Test func reorderPersists() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try manager(h).reorder([useCaseMeds.id, useCaseSleep.id])
        #expect(h.store.stored?.trackers.map(\.id) == [useCaseMeds.id, useCaseSleep.id])
        try manager(h).rename(useCaseMeds.id, to: "Pills")
        try manager(h).setSymbol(useCaseMeds.id, to: "cross.case.fill")
        let meds = try #require(h.store.stored?.trackers.first)
        #expect(meds.name == "Pills")
        #expect(meds.symbol == "cross.case.fill")
    }
}
