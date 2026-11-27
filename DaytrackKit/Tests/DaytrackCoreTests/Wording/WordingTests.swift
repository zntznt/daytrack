import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }

private let anxiety = Tracker(name: "Anxiety", symbol: "wind", type: .ordinal, createdAt: day("2027-01-01"))
private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric,
                            anchors: .init(low: "None", high: "Deep"), createdAt: day("2027-01-01"))
private let newWords = ["None", "Slight", "Some", "Strong", "Overwhelming"]
private let today = day("2027-07-22")

private func entry(_ d: String, _ values: [UUID: DayValue]) -> DayEntry {
    DayEntry(date: day(d), values: values, firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0)
}

private func record(closedThrough: String?, entries: [DayEntry] = []) -> Record {
    Record(settings: Settings(closedThrough: closedThrough.map(day)), trackers: [anxiety, sleep],
           entries: Dictionary(uniqueKeysWithValues: entries.map { ($0.date, $0) }))
}

@Suite struct WordingTests {
    @Test func editIsFreeBeforeAnyClosedValue() throws {
        let r = try WordingEditRule.edit(anxiety.id, labels: newWords, anchors: nil, in: record(closedThrough: "2027-07-21"), today: today)
        #expect(r.revisions.isEmpty)
        #expect(r.trackers[0].labels == newWords)
    }

    @Test func editAfterClosedValueCreatesRevisionFromToday() throws {
        let rec = record(closedThrough: "2027-07-21", entries: [entry("2027-07-20", [anxiety.id: .set(5)])])
        let r = try WordingEditRule.edit(anxiety.id, labels: newWords, anchors: nil, in: rec, today: today)
        #expect(r.revisions.count == 1)
        let rev = try #require(r.revisions.first)
        #expect(rev.trackerId == anxiety.id)
        #expect(rev.effectiveFrom == today)
        #expect(rev.previousLabels == anxiety.labels)
        #expect(r.trackers[0].labels == newWords)
    }

    @Test func closedSkipAlsoFreezesWording() throws {
        let rec = record(closedThrough: "2027-07-21", entries: [entry("2027-07-20", [anxiety.id: .skip])])
        #expect(WordingEditRule.isFrozen(anxiety, in: rec))
        let r = try WordingEditRule.edit(anxiety.id, labels: newWords, anchors: nil, in: rec, today: today)
        #expect(r.revisions.count == 1)
    }

    @Test func openDayValuesDoNotFreezeWording() throws {
        let rec = record(closedThrough: "2027-07-20", entries: [
            entry("2027-07-21", [anxiety.id: .set(5)]), entry("2027-07-22", [anxiety.id: .skip]),
            entry("2027-07-19", [sleep.id: .set(3)]),
        ])
        #expect(!WordingEditRule.isFrozen(anxiety, in: rec))
        let r = try WordingEditRule.edit(anxiety.id, labels: newWords, anchors: nil, in: rec, today: today)
        #expect(r.revisions.isEmpty)
    }

    @Test func stopCountChangeRefused() {
        #expect(throws: WordingError.stopCountIsFixed) {
            try WordingEditRule.edit(anxiety.id, labels: ["Low", "Mid", "High"], anchors: nil, in: record(closedThrough: nil), today: today)
        }
    }

    @Test func revisionWithWrongStopCountRejected() {
        #expect(throws: WordingError.stopCountIsFixed) {
            try ScaleRevision(tracker: anxiety, effectiveFrom: today, previousLabels: ["No", "Yes"])
        }
    }

    @Test func labelsOnDateUseOldWordsBeforeBoundary() throws {
        var current = anxiety
        current.labels = newWords
        let eras = Eras([try ScaleRevision(tracker: anxiety, effectiveFrom: day("2027-05-01"), previousLabels: anxiety.labels)])
        #expect(eras.labels(current, on: day("2027-04-30")) == anxiety.labels)
        #expect(eras.labels(current, on: day("2027-05-01")) == newWords)
        #expect(eras.eras(for: current).count == 2)
    }

    @Test func latestEraInsideRangeEndingInPastIgnoresLaterRevision() throws {
        let eras = Eras([
            try ScaleRevision(tracker: anxiety, effectiveFrom: day("2027-03-10"), previousLabels: anxiety.labels),
            try ScaleRevision(tracker: anxiety, effectiveFrom: day("2027-06-01"), previousLabels: newWords),
        ])
        let range = DateRange(start: day("2027-03-01"), end: day("2027-03-31"))!
        #expect(eras.latestEra(anxiety, in: range) == DateRange(start: day("2027-03-10"), end: day("2027-03-31")))
        let before = DateRange(start: day("2027-02-01"), end: day("2027-02-28"))!
        #expect(eras.latestEra(anxiety, in: before) == before)
    }

    @Test func boundaryIsAbsoluteDateForRangeEndingThirtyDaysAgo() throws {
        let revisedOn = day("2027-05-01")
        let eras = Eras([try ScaleRevision(tracker: anxiety, effectiveFrom: revisedOn, previousLabels: anxiety.labels)])
        let range = DateRange.last(90, endingOn: today.adding(days: -30))
        #expect(eras.boundaries(anxiety, in: range) == [revisedOn])
        #expect(eras.latestEra(anxiety, in: range).start == revisedOn)
        #expect(eras.boundaries(anxiety, in: DateRange(start: revisedOn, end: today)!).isEmpty)
    }

    @Test func anchorsFollowSameRule() throws {
        let deep = Tracker.Anchors(low: "Awake", high: "Deep")
        let free = try WordingEditRule.edit(sleep.id, labels: [], anchors: deep, in: record(closedThrough: "2027-07-21"), today: today)
        #expect(free.revisions.isEmpty)
        #expect(free.trackers[1].anchors == deep)

        let rec = record(closedThrough: "2027-07-21", entries: [entry("2027-07-20", [sleep.id: .set(4)])])
        let r = try WordingEditRule.edit(sleep.id, labels: [], anchors: deep, in: rec, today: today)
        let rev = try #require(r.revisions.first)
        #expect(rev.previousAnchors == sleep.anchors)
        #expect(Eras(r.revisions).anchors(r.trackers[1], on: day("2027-07-21")) == sleep.anchors)
        #expect(Eras(r.revisions).anchors(r.trackers[1], on: today) == deep)
    }

    @Test func secondEditTodayKeepsOneRevisionAndRevertDropsIt() throws {
        let rec = record(closedThrough: "2027-07-21", entries: [entry("2027-07-20", [anxiety.id: .set(5)])])
        let once = try WordingEditRule.edit(anxiety.id, labels: newWords, anchors: nil, in: rec, today: today)
        var other = newWords
        other[0] = "Nothing"
        let twice = try WordingEditRule.edit(anxiety.id, labels: other, anchors: nil, in: once, today: today)
        #expect(twice.revisions.count == 1)
        #expect(twice.revisions[0].previousLabels == anxiety.labels)
        let back = try WordingEditRule.edit(anxiety.id, labels: anxiety.labels, anchors: nil, in: twice, today: today)
        #expect(back.revisions.isEmpty)
    }
}
