import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }
private let start = day("2027-03-01")
private let march = DateRange.last(31, endingOn: day("2027-03-31"))

private func tracker(_ name: String) -> Tracker {
    Tracker(name: name, symbol: "sun.max", type: .numeric, createdAt: day("2027-01-01"))
}

/// `values[i]` is written on March 1 + i for every tracker given.
private func record(_ trackers: [Tracker], _ values: [DayValue], revisions: [ScaleRevision] = []) -> Record {
    let entries = values.enumerated().map { i, v in
        let d = start.adding(days: i)
        return (d, DayEntry(date: d, values: Dictionary(uniqueKeysWithValues: trackers.map { ($0.id, v) }),
                            firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0))
    }
    return Record(trackers: trackers, revisions: revisions, entries: Dictionary(uniqueKeysWithValues: entries))
}

@Suite struct FloorsTests {
    @Test func thirteenValuesShortfallOfOne() {
        let mood = tracker("Mood")
        let s = Floors.reportShortfall(mood, range: march, record: record([mood], Array(repeating: .set(5), count: 13)))
        #expect(s == Shortfall(count: 13, threshold: 14))
        #expect(s.remaining == 1)
        #expect(!s.passes)
        let met = Floors.reportShortfall(mood, range: march, record: record([mood], Array(repeating: .set(5), count: 15)))
        #expect(met.remaining == 0)
        #expect(met.passes)
    }

    @Test func skipsDoNotCountTowardFloor() {
        let mood = tracker("Mood")
        let values = Array(repeating: DayValue.set(5), count: 10) + Array(repeating: .skip, count: 10)
        let s = Floors.reportShortfall(mood, range: march, record: record([mood], values))
        #expect(s.count == 10)
        #expect(s.remaining == 4)
    }

    @Test func floorUsesLatestEraInRange() throws {
        let mood = tracker("Mood")
        // 20 values from March 1; a revision on March 11 leaves 10 in the latest era.
        let rev = try ScaleRevision(tracker: mood, effectiveFrom: day("2027-03-11"), previousLabels: [])
        let rec = record([mood], Array(repeating: .set(5), count: 20), revisions: [rev])
        #expect(Floors.reportShortfall(mood, range: march, record: rec).count == 10)
        // A range ending before the revision keeps its own era (Q5 amendment).
        let before = DateRange(start: start, end: day("2027-03-10"))!
        #expect(Floors.reportShortfall(mood, range: before, record: rec).count == 10)
    }

    @Test func builderEnabledWhenOneSelectedTrackerPasses() {
        let mood = tracker("Mood"), sleep = tracker("Sleep")
        var rec = record([mood], Array(repeating: .set(5), count: 14))
        rec.trackers.append(sleep)
        #expect(Floors.builderCanGenerate(selected: [mood, sleep], range: march, record: rec))
        #expect(!Floors.builderCanGenerate(selected: [sleep], range: march, record: rec))
        #expect(!Floors.builderCanGenerate(selected: [], range: march, record: rec))
    }

    @Test func historyEmptyThresholds() {
        #expect(Floors.historyChart == 1)
        #expect(Floors.historyLine == 2)
        #expect(Floors.historySplit == 12)
        #expect(Floors.report == 14)
        #expect(Floors.pair == 12)
    }
}
