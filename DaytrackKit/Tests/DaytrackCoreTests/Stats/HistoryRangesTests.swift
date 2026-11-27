import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }
private let mood = Tracker(name: "Mood", symbol: "sun.max", type: .numeric, createdAt: day("2026-01-01"))

private func entry(_ d: String, _ v: DayValue?, note: String? = nil) -> (DayKey, DayEntry) {
    (day(d), DayEntry(date: day(d), values: v.map { [mood.id: $0] } ?? [:], note: note,
                      firstWrittenAt: .distantPast, lastWrittenAt: .distantPast, tzOffsetAtWrite: 0))
}

private func record(_ entries: [(DayKey, DayEntry)], closedThrough: DayKey? = nil) -> Record {
    Record(settings: Settings(closedThrough: closedThrough), trackers: [mood], entries: Dictionary(uniqueKeysWithValues: entries))
}

@Suite struct HistoryRangesTests {
    @Test func recordStartIsFirstDayWithAnythingWritten() {
        #expect(HistoryRanges.recordStart(Record()) == nil)
        let rec = record([entry("2027-03-01", .skip), entry("2027-03-02", nil, note: "n"),
                          entry("2027-03-05", .set(4)), entry("2027-03-09", .set(1))])
        #expect(HistoryRanges.recordStart(rec) == day("2027-03-05"))
    }

    @Test func rangesAppearAt30_90_365DaysOfRecord() {
        let start = day("2027-01-01")
        func kinds(age: Int) -> [HistoryRanges.Kind] {
            HistoryRanges(recordStart: start, end: start.adding(days: age - 1)).options.map(\.kind)
        }
        #expect(HistoryRanges(recordStart: nil, end: start).options.isEmpty)
        #expect(kinds(age: 1) == [.soFar])
        #expect(kinds(age: 29) == [.soFar])
        #expect(kinds(age: 30) == [.last30])
        #expect(kinds(age: 89) == [.last30])
        #expect(kinds(age: 90) == [.last30, .last90])
        #expect(kinds(age: 364) == [.last30, .last90])
        #expect(kinds(age: 365) == [.last30, .last90, .twelveMonths])
        let soFar = HistoryRanges(recordStart: start, end: day("2027-01-10")).options[0].range
        #expect(soFar == DateRange(start: start, end: day("2027-01-10")))
    }

    @Test func twelveMonthsIsRollingNotCalendarYear() {
        let ranges = HistoryRanges(recordStart: day("2025-01-01"), end: day("2026-07-15"))
        let year = ranges.options.first { $0.kind == .twelveMonths }!.range
        #expect(year == DateRange.last(365, endingOn: day("2026-07-15")))
        #expect(year.start == day("2025-07-16"))
    }

    @Test func reportRangeEndsAtClosedThrough() {
        let rec = record([entry("2027-01-01", .set(5))], closedThrough: day("2027-02-14"))
        let report = HistoryRanges.report(rec)
        #expect(report.options.map(\.kind) == [.last30])
        #expect(report.options.allSatisfy { $0.range.end == day("2027-02-14") })
        // Nothing closed yet: no report range.
        #expect(HistoryRanges.report(record([entry("2027-01-01", .set(5))])).options.isEmpty)
    }

    @Test func historyRangeEndsToday() {
        let rec = record([entry("2027-01-01", .set(5))], closedThrough: day("2027-04-01"))
        let history = HistoryRanges.history(rec, today: day("2027-04-02"))
        #expect(history.options.map(\.kind) == [.last30, .last90])
        #expect(history.options.allSatisfy { $0.range.end == day("2027-04-02") })
    }
}
