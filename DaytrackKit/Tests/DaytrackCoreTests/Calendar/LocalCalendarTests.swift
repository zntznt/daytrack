import Foundation
import Testing
@testable import DaytrackCore

@Suite struct LocalCalendarTests {
    @Test func sameInstantIsDifferentDayInAucklandAndLosAngeles() {
        // 2027-07-22T12:00:00Z: Auckland (UTC+12) is on the 23rd, Los Angeles (UTC-7) still on the 22nd.
        let instant = Date(timeIntervalSince1970: 1_816_257_600)
        let auckland = LocalCalendar(timeZone: TimeZone(identifier: "Pacific/Auckland")!)
        let losAngeles = LocalCalendar(timeZone: TimeZone(identifier: "America/Los_Angeles")!)
        #expect(auckland.dayKey(for: instant) == DayKey("2027-07-23"))
        #expect(losAngeles.dayKey(for: instant) == DayKey("2027-07-22"))
    }

    @Test func startOfDayMapsBackToSameDay() {
        let cal = LocalCalendar(timeZone: TimeZone(identifier: "America/Los_Angeles")!)
        let day = DayKey("2027-03-14")!  // US daylight-saving change day
        let start = cal.startOfDay(day)
        #expect(cal.dayKey(for: start) == day)
        #expect(cal.dayKey(for: start.addingTimeInterval(-1)) == DayKey("2027-03-13"))
    }

    @Test func weekdayOfKnownDates() {
        let cal = LocalCalendar(timeZone: TimeZone(identifier: "Pacific/Auckland")!)
        #expect(cal.weekday(of: DayKey("2027-07-22")!) == 5)  // Thursday
        #expect(cal.weekday(of: DayKey("2028-02-29")!) == 3)  // Tuesday
        #expect(cal.adding(days: 7, to: DayKey("2027-07-22")!) == DayKey("2027-07-29"))
    }
}
