import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }
private func range(_ a: String, _ b: String) -> DateRange { DateRange(start: day(a), end: day(b))! }

private let mood = Tracker(name: "Mood", symbol: "sun.max", type: .numeric, createdAt: day("2027-01-01"))
private let anxiety = Tracker(name: "Anxiety", symbol: "wind", type: .ordinal, createdAt: day("2027-01-01"))
private let walked = Tracker(name: "Walked", symbol: "figure.walk", type: .binary, createdAt: day("2027-01-01"))

/// One entry per day, all for `tracker`.
private func record(_ tracker: Tracker, _ values: [String: DayValue], revisions: [ScaleRevision] = []) -> Record {
    let entries = values.map { d, v in
        (day(d), DayEntry(date: day(d), values: [tracker.id: v], firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0))
    }
    return Record(trackers: [tracker], revisions: revisions, entries: Dictionary(uniqueKeysWithValues: entries))
}

@Suite struct TrackerSummaryTests {
    @Test func meanExcludesSkipsAndBlanks() {
        let rec = record(mood, ["2027-03-01": .set(2), "2027-03-02": .skip, "2027-03-04": .set(6)])
        let s = TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-05"), record: rec)
        #expect(s.mean == 4)
        #expect(s.n == 2)
        #expect(s.skips == 1)
        #expect(s.blanks == 2)
    }

    @Test func emptyRangeMeanIsNil_notZero() {
        let s = TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-03"), record: record(mood, ["2027-03-02": .skip]))
        #expect(s.n == 0)
        #expect(s.mean == nil)
        #expect(s.high == nil)
        #expect(s.low == nil)
    }

    @Test func blanksClippedToActiveSpan() {
        let t = Tracker(name: "Mood", symbol: "sun.max", type: .numeric, createdAt: day("2027-03-03"),
                        archivedRanges: [.init(from: day("2027-03-06"), to: day("2027-03-07"))])
        let s = TrackerSummary(tracker: t, range: range("2027-03-01", "2027-03-10"), record: record(t, ["2027-03-04": .set(5)]))
        // Active: 3rd–5th and 8th–10th = 6 days, one set.
        #expect(s.blanks == 5)
        #expect(s.n == 1)
    }

    @Test func summaryNeverSpansTwoWordings() throws {
        let rev = try ScaleRevision(tracker: anxiety, effectiveFrom: day("2027-03-05"), previousLabels: TrackerType.ordinal.defaultLabels)
        let rec = record(anxiety, ["2027-03-02": .set(10), "2027-03-03": .skip, "2027-03-06": .set(2.5), "2027-03-07": .set(5)], revisions: [rev])
        let s = TrackerSummary(tracker: anxiety, range: range("2027-03-01", "2027-03-08"), record: rec)
        #expect(s.windowedRange == range("2027-03-05", "2027-03-08"))
        #expect(s.mean == 3.75)
        #expect(s.high == 5)
        #expect(s.skips == 0)
        #expect(s.blanks == 2)
    }

    @Test func reducedNReportedWhenRangeCrossesRevision() throws {
        let rev = try ScaleRevision(tracker: mood, effectiveFrom: day("2027-03-04"), previousLabels: [])
        let rec = record(mood, ["2027-03-01": .set(1), "2027-03-02": .set(2), "2027-03-04": .set(4)], revisions: [rev])
        let crossing = TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-05"), record: rec)
        #expect(crossing.crossesBoundary)
        #expect(crossing.n == 1)
        // A range starting on the revision date splits nothing.
        let after = TrackerSummary(tracker: mood, range: range("2027-03-04", "2027-03-05"), record: rec)
        #expect(!after.crossesBoundary)
        #expect(after.windowedRange == range("2027-03-04", "2027-03-05"))
        // A range ending before the revision keeps its own era (Q5 amendment).
        let before = TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-03"), record: rec)
        #expect(!before.crossesBoundary)
        #expect(before.n == 2)
    }

    @Test func binaryReportedAsKOfN() {
        let rec = record(walked, ["2027-03-01": .set(10), "2027-03-02": .set(0), "2027-03-03": .set(10), "2027-03-04": .skip])
        let s = TrackerSummary(tracker: walked, range: range("2027-03-01", "2027-03-04"), record: rec)
        #expect(s.k == 2)
        #expect(s.n == 3)
        #expect(s.distribution == nil)
        #expect(TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-04"), record: record(mood, [:])).k == nil)
    }

    @Test func ordinalMedianAndDistributionWithN() {
        // Indices 0, 1, 1, 3 → lower median 1.
        let rec = record(anxiety, ["2027-03-01": .set(0), "2027-03-02": .set(2.5), "2027-03-03": .set(2.5), "2027-03-04": .set(7.5), "2027-03-05": .skip])
        let s = TrackerSummary(tracker: anxiety, range: range("2027-03-01", "2027-03-05"), record: rec)
        #expect(s.n == 4)
        #expect(s.distribution == [1, 2, 0, 1, 0])
        #expect(s.medianIndex == 1)
        #expect(s.k == nil)
        let one = TrackerSummary(tracker: anxiety, range: range("2027-03-04", "2027-03-04"), record: rec)
        #expect(one.medianIndex == 3)
        let none = TrackerSummary(tracker: anxiety, range: range("2027-03-05", "2027-03-06"), record: rec)
        #expect(none.medianIndex == nil)
        #expect(none.distribution == [0, 0, 0, 0, 0])
    }

    @Test func highAndLowComeFromSetValuesOnly() {
        let rec = record(mood, ["2027-03-01": .set(3), "2027-03-02": .skip, "2027-03-04": .set(7)])
        let s = TrackerSummary(tracker: mood, range: range("2027-03-01", "2027-03-05"), record: rec)
        #expect(s.high == 7)
        #expect(s.low == 3)
    }
}
