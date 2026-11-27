import Foundation
import Testing
@testable import DaytrackCore

private let newYork = TimeZone(identifier: "America/New_York")!
private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

/// A local wall-clock instant in `tz`.
private func at(_ day: String, _ hour: Int, _ minute: Int = 0, in tz: TimeZone) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let d = DayKey(day)!
    return cal.date(from: DateComponents(year: d.year, month: d.month, day: d.day, hour: hour, minute: minute))!
}

private func day(_ s: String) -> DayKey { DayKey(s)! }

@Suite struct DayClosingTests {
    @Test func lockHour23_yesterdayOpenUntil23OnNextDay() {
        let now = at("2027-07-23", 10, in: newYork)
        let close = at("2027-07-23", 23, in: newYork)
        #expect(DayClosing.closeInstant(day("2027-07-22"), lockHour: 23, tz: newYork) == close)
        #expect(DayClosing.status(of: day("2027-07-22"), now: now, lockHour: 23, closedThrough: day("2027-07-21"), tz: newYork)
                == .yesterdayOpen(until: close))
        #expect(DayClosing.status(of: day("2027-07-22"), now: close, lockHour: 23, closedThrough: day("2027-07-21"), tz: newYork)
                == .closed)
    }

    @Test func lockHour20_closesAt20OnNextDay() {
        let close = at("2027-07-23", 20, in: newYork)
        #expect(DayClosing.closeInstant(day("2027-07-22"), lockHour: 20, tz: newYork) == close)
        let before = close.addingTimeInterval(-1)
        #expect(DayClosing.status(of: day("2027-07-22"), now: before, lockHour: 20, closedThrough: nil, tz: newYork)
                == .yesterdayOpen(until: close))
        #expect(DayClosing.status(of: day("2027-07-22"), now: close, lockHour: 20, closedThrough: nil, tz: newYork) == .closed)
        #expect(DayClosing.advanceClosedThrough(nil, now: close, lockHour: 20, tz: newYork) == day("2027-07-22"))
        #expect(DayClosing.advanceClosedThrough(nil, now: before, lockHour: 20, tz: newYork) == day("2027-07-21"))
    }

    @Test func lockHour0_noGraceDay_yesterdayClosedAtMidnight() {
        let midnight = at("2027-07-23", 0, in: newYork)
        #expect(DayClosing.closeInstant(day("2027-07-22"), lockHour: 0, tz: newYork) == midnight)
        #expect(DayClosing.status(of: day("2027-07-22"), now: midnight, lockHour: 0, closedThrough: nil, tz: newYork) == .closed)
        #expect(DayClosing.status(of: day("2027-07-22"), now: midnight.addingTimeInterval(-1), lockHour: 0, closedThrough: nil, tz: newYork)
                == .today)
        #expect(DayClosing.advanceClosedThrough(nil, now: midnight, lockHour: 0, tz: newYork) == day("2027-07-22"))
    }

    @Test func springForwardGap_closesAtFirstInstantAfter() {
        // 02:00 does not exist on 2027-03-14 in New York; clocks jump from 01:59:59 EST to 03:00 EDT.
        let close = DayClosing.closeInstant(day("2027-03-13"), lockHour: 2, tz: newYork)
        #expect(close == Date(timeIntervalSince1970: 1_805_011_200))  // 2027-03-14T07:00:00Z = 03:00 EDT
        #expect(close == at("2027-03-14", 3, in: newYork))
    }

    @Test func fallBack_closesAtFirstOccurrence() {
        // 01:00 happens twice on 2027-11-07 in New York; the first is EDT (UTC-4).
        let close = DayClosing.closeInstant(day("2027-11-06"), lockHour: 1, tz: newYork)
        #expect(close == Date(timeIntervalSince1970: 1_825_570_800))  // 2027-11-07T05:00:00Z = 01:00 EDT
    }

    @Test func raisingLockHourNeverReopensClosedDay() {
        // Lock hour 20; it is 21:00, so yesterday closed an hour ago and closedThrough moved to it.
        let now = at("2027-07-23", 21, in: newYork)
        let ct = DayClosing.advanceClosedThrough(day("2027-07-21"), now: now, lockHour: 20, tz: newYork)
        #expect(ct == day("2027-07-22"))
        #expect(DayClosing.lockHourChange(from: 20, to: 23, now: now, closedThrough: ct, tz: newYork) == .applies)
        #expect(DayClosing.status(of: day("2027-07-22"), now: now, lockHour: 23, closedThrough: ct, tz: newYork) == .closed)
        #expect(DayClosing.advanceClosedThrough(ct, now: now, lockHour: 23, tz: newYork) == ct)
    }

    @Test func loweringLockHourBelowNowReportsClosesYesterdayNow() {
        let now = at("2027-07-23", 21, in: newYork)
        let ct = day("2027-07-21")
        #expect(DayClosing.status(of: day("2027-07-22"), now: now, lockHour: 23, closedThrough: ct, tz: newYork)
                == .yesterdayOpen(until: at("2027-07-23", 23, in: newYork)))
        #expect(DayClosing.lockHourChange(from: 23, to: 20, now: now, closedThrough: ct, tz: newYork) == .closesYesterdayNow)
        #expect(DayClosing.lockHourChange(from: 23, to: 22, now: now, closedThrough: ct, tz: newYork) == .applies)
        #expect(DayClosing.advanceClosedThrough(ct, now: now, lockHour: 20, tz: newYork) == day("2027-07-22"))
    }

    @Test func travellingWestNeverReopens() {
        // Yesterday closed at 23:00 in New York; three zones west the local clock reads 20:30.
        let now = at("2027-07-23", 23, 30, in: newYork)
        let ct = DayClosing.advanceClosedThrough(day("2027-07-21"), now: now, lockHour: 23, tz: newYork)
        #expect(ct == day("2027-07-22"))
        #expect(DayClosing.status(of: day("2027-07-22"), now: now, lockHour: 23, closedThrough: ct, tz: losAngeles) == .closed)
        #expect(DayClosing.advanceClosedThrough(ct, now: now, lockHour: 23, tz: losAngeles) == ct)
    }

    @Test func travellingEastNeverRedatesADay() {
        // Today in Los Angeles is 2027-07-22; landing in Tokyo it is already the 23rd there.
        let now = at("2027-07-22", 20, in: losAngeles)
        #expect(LocalCalendar(timeZone: losAngeles).dayKey(for: now) == day("2027-07-22"))
        #expect(LocalCalendar(timeZone: tokyo).dayKey(for: now) == day("2027-07-23"))
        // The 22nd stays the 22nd and closes at the lock hour on the clock in hand: 23:00 Tokyo on the 23rd.
        let close = at("2027-07-23", 23, in: tokyo)
        #expect(DayClosing.status(of: day("2027-07-22"), now: now, lockHour: 23, closedThrough: day("2027-07-21"), tz: tokyo)
                == .yesterdayOpen(until: close))
        #expect(DayClosing.status(of: day("2027-07-23"), now: now, lockHour: 23, closedThrough: day("2027-07-21"), tz: tokyo) == .today)
    }

    @Test func futureDayIsNotWritable() {
        let now = at("2027-07-22", 23, 59, in: newYork)
        #expect(DayClosing.status(of: day("2027-07-23"), now: now, lockHour: 23, closedThrough: nil, tz: newYork) == .future)
        #expect(DayClosing.status(of: day("2028-01-01"), now: now, lockHour: 0, closedThrough: nil, tz: newYork) == .future)
    }

    @Test func todayIsWritableUntilItsCloseInstant() {
        let d = day("2027-07-22")
        #expect(DayClosing.status(of: d, now: at("2027-07-22", 0, in: newYork), lockHour: 23, closedThrough: nil, tz: newYork) == .today)
        #expect(DayClosing.status(of: d, now: at("2027-07-22", 23, 59, in: newYork), lockHour: 23, closedThrough: nil, tz: newYork) == .today)
        let close = DayClosing.closeInstant(d, lockHour: 23, tz: newYork)
        #expect(DayClosing.status(of: d, now: close.addingTimeInterval(-1), lockHour: 23, closedThrough: nil, tz: newYork)
                == .yesterdayOpen(until: close))
        #expect(DayClosing.status(of: d, now: close, lockHour: 23, closedThrough: nil, tz: newYork) == .closed)
    }

    @Test func nextBoundaryIsEarlierOfMidnightAndClose() {
        // Before yesterday's close, the close comes first.
        #expect(DayClosing.nextBoundary(now: at("2027-07-23", 10, in: newYork), lockHour: 20, tz: newYork)
                == at("2027-07-23", 20, in: newYork))
        // After it, the next midnight is the boundary.
        #expect(DayClosing.nextBoundary(now: at("2027-07-23", 21, in: newYork), lockHour: 20, tz: newYork)
                == at("2027-07-24", 0, in: newYork))
        // Lock hour 0: only midnights.
        #expect(DayClosing.nextBoundary(now: at("2027-07-23", 10, in: newYork), lockHour: 0, tz: newYork)
                == at("2027-07-24", 0, in: newYork))
    }
}
