import Testing
@testable import DaytrackCore

@Suite struct DateRangeTests {
    @Test func rangeCountIsInclusive() throws {
        let range = try #require(DateRange(start: DayKey("2027-12-30")!, end: DayKey("2028-01-02")!))
        #expect(range.count == 4)
        #expect(range.days.map(\.isoString) == ["2027-12-30", "2027-12-31", "2028-01-01", "2028-01-02"])
        #expect(range.contains(range.start) && range.contains(range.end))
        #expect(DateRange(start: DayKey("2028-01-02")!, end: DayKey("2027-12-30")!) == nil)
    }

    @Test func rangeOfOneDayHasCountOne() throws {
        let day = DayKey("2027-07-22")!
        let range = try #require(DateRange(start: day, end: day))
        #expect(range.count == 1)
        #expect(DateRange.last(1, endingOn: day) == range)
    }

    @Test func lastNDaysEndsOnGivenDayInclusive() {
        let range = DateRange.last(90, endingOn: DayKey("2027-07-22")!)
        #expect(range.start == DayKey("2027-04-24"))
        #expect(range.end == DayKey("2027-07-22"))
        #expect(range.count == 90)
    }
}
