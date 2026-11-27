import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }

private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-07-01"))
private let mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: day("2027-07-01"))
private let meds = Tracker(name: "Meds taken", symbol: "pills.fill", type: .binary, createdAt: day("2027-07-01"))

private func entry(_ date: String, _ values: [UUID: DayValue]) -> DayEntry {
    DayEntry(date: day(date), values: values, firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0)
}

@Suite struct DayCountsTests {
    @Test func countsReadWrittenSkippedBlank() {
        let late = Tracker(name: "Home", symbol: "house.fill", type: .numeric, createdAt: day("2027-07-23"))
        let e = entry("2027-07-22", [sleep.id: .set(7), mood.id: .skip])
        let rows = RowCounts(entry: e, day: day("2027-07-22"), trackers: [sleep, mood, meds, late])
        #expect(rows == RowCounts(written: 1, skipped: 1, blank: 1))
        #expect(RowCounts(entry: nil, day: day("2027-07-22"), trackers: [sleep, mood]).blank == 2)
    }

    @Test func skippedOnlyDayCountedSeparatelyFromWritten() {
        let entries = [
            day("2027-07-20"): entry("2027-07-20", [sleep.id: .set(7), mood.id: .skip]),
            day("2027-07-21"): entry("2027-07-21", [sleep.id: .skip, mood.id: .skip]),
        ]
        let range = DateRange(start: day("2027-07-20"), end: day("2027-07-22"))!
        let counts = DayCounts(entries: entries, range: range, trackers: [sleep, mood])
        #expect(counts.written == 1)
        #expect(counts.skippedOnly == 1)
        #expect(counts.blank == 1)
    }

    @Test func countsExcludeTrackersNotSelected() {
        let entries = [day("2027-07-20"): entry("2027-07-20", [meds.id: .set(10), mood.id: .skip])]
        let range = DateRange(start: day("2027-07-20"), end: day("2027-07-20"))!
        #expect(DayCounts(entries: entries, range: range, trackers: [sleep, mood]).skippedOnly == 1)
        #expect(DayCounts(entries: entries, range: range, trackers: [sleep]).blank == 1)
        #expect(RowCounts(entry: entries[day("2027-07-20")], day: day("2027-07-20"), trackers: [sleep, mood])
                == RowCounts(written: 0, skipped: 1, blank: 1))
        // Days before every selected tracker existed are not counted at all.
        let early = DateRange(start: day("2027-06-29"), end: day("2027-06-30"))!
        #expect(DayCounts(entries: [:], range: early, trackers: [sleep]) == DayCounts(written: 0, skippedOnly: 0, blank: 0))
    }
}
