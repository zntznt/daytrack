import Foundation
import Testing
@testable import DaytrackCore

@Suite struct DayKeyTests {
    @Test func formatsAndParsesISODate() throws {
        let key = try #require(DayKey(year: 2027, month: 7, day: 2))
        #expect(key.isoString == "2027-07-02")
        #expect(DayKey("2027-07-02") == key)

        let json = try JSONEncoder().encode([key])
        #expect(String(decoding: json, as: UTF8.self) == #"["2027-07-02"]"#)
        #expect(try JSONDecoder().decode([DayKey].self, from: json) == [key])
    }

    @Test func invalidStringRejected() {
        for bad in ["", "2027-7-02", "2027-07-2", "27-07-02", "2027-13-01", "2027-02-29",
                    "2027-00-10", "2027-07-00", "2027/07/02", "2027-07-02T00:00", " 2027-07-02", "+027-07-02"] {
            #expect(DayKey(bad) == nil, "\(bad)")
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([DayKey].self, from: Data(#"["2027-02-30"]"#.utf8))
        }
    }

    @Test func addingDaysCrossesMonthAndYear() {
        #expect(DayKey("2027-01-31")!.adding(days: 1) == DayKey("2027-02-01"))
        #expect(DayKey("2027-12-31")!.adding(days: 1) == DayKey("2028-01-01"))
        #expect(DayKey("2028-01-01")!.adding(days: -1) == DayKey("2027-12-31"))
        #expect(DayKey("2027-03-01")!.adding(days: -1) == DayKey("2027-02-28"))
        #expect(DayKey("2027-12-31")!.days(to: DayKey("2028-01-02")!) == 2)
        #expect(DayKey("2027-12-31")! < DayKey("2028-01-01")!)
    }

    @Test func leapDay2028Exists() {
        #expect(DayKey("2028-02-29") != nil)
        #expect(DayKey("2028-02-28")!.adding(days: 1) == DayKey("2028-02-29"))
        #expect(DayKey("2028-02-29")!.adding(days: 1) == DayKey("2028-03-01"))
    }
}
