import Foundation
import Testing
@testable import DaytrackCore

private let newYork = TimeZone(identifier: "America/New_York")!
private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

private func at(_ day: String, _ hour: Int, in tz: TimeZone = newYork) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let d = DayKey(day)!
    return cal.date(from: DateComponents(year: d.year, month: d.month, day: d.day, hour: hour))!
}

private func day(_ s: String) -> DayKey { DayKey(s)! }

private let d = day("2027-07-22")
private func ctx(_ now: Date, status: DayStatus = .today, tz: TimeZone = newYork) -> WriteContext {
    WriteContext(day: d, status: status, now: now, tz: tz)
}

private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-07-01"))
private let anxiety = Tracker(name: "Anxiety", symbol: "wind", type: .ordinal, createdAt: day("2027-07-01"))
private let meds = Tracker(name: "Meds taken", symbol: "pills.fill", type: .binary, createdAt: day("2027-07-01"))

@Suite struct WritesTests {
    @Test func firstWriteSetsFirstAndLastWrittenAt() throws {
        let now = at("2027-07-22", 9)
        let e = try Writes.set(7, for: sleep, in: nil, ctx(now))
        #expect(e.date == d)
        #expect(e.firstWrittenAt == now)
        #expect(e.lastWrittenAt == now)
        #expect(e.values[sleep.id] == .set(7))
        #expect(e.origin == .device)
        #expect(e.importedAt == nil)
        #expect(!e.writtenNextDay)
    }

    @Test func laterWriteKeepsFirstWrittenAt() throws {
        let first = at("2027-07-22", 9), later = at("2027-07-22", 21)
        let e = try Writes.set(5, for: sleep, in: Writes.set(7, for: sleep, in: nil, ctx(first)), ctx(later))
        #expect(e.firstWrittenAt == first)
        #expect(e.lastWrittenAt == later)
        #expect(e.values[sleep.id] == .set(5))
    }

    @Test func writeOnFollowingDaySetsWrittenNextDay() throws {
        let e = try Writes.set(7, for: sleep, in: nil, ctx(at("2027-07-22", 22)))
        #expect(!e.writtenNextDay)
        let next = try Writes.set(6, for: sleep, in: e, ctx(at("2027-07-23", 10), status: .yesterdayOpen(until: at("2027-07-23", 23))))
        #expect(next.writtenNextDay)
        // Once set it stays set, even after a later same-day-looking write.
        let back = try Writes.set(5, for: sleep, in: next, ctx(at("2027-07-22", 23)))
        #expect(back.writtenNextDay)
    }

    @Test func tzOffsetStoredAtWrite() throws {
        let e = try Writes.set(7, for: sleep, in: nil, ctx(at("2027-07-22", 9)))
        #expect(e.tzOffsetAtWrite == -4 * 3600)
        let moved = try Writes.skip(anxiety, in: e, ctx(at("2027-07-22", 23, in: tokyo), tz: tokyo))
        #expect(moved.tzOffsetAtWrite == 9 * 3600)
    }

    @Test func noteSkipAndClearAllCountAsWrites() throws {
        let t0 = at("2027-07-22", 9)
        let base = try Writes.set(7, for: sleep, in: nil, ctx(t0))
        let open = ctx(at("2027-07-23", 8), status: .yesterdayOpen(until: at("2027-07-23", 23)))
        let noted = try Writes.setNote("slept badly", in: base, open)
        let skipped = try Writes.skip(anxiety, in: base, open)
        let cleared = try Writes.clear(sleep.id, in: base, open)
        for e in [noted, skipped, cleared] {
            #expect(e.lastWrittenAt == open.now)
            #expect(e.firstWrittenAt == t0)
            #expect(e.writtenNextDay)
        }
        #expect(noted.note == "slept badly")
        #expect(try Writes.setNote("", in: noted, open).note == nil)
    }

    @Test func clearRemovesKey_neverStoresSkip() throws {
        let c = ctx(at("2027-07-22", 9))
        let set = try Writes.set(7, for: sleep, in: nil, c)
        let skip = try Writes.skip(anxiety, in: set, c)
        let cleared = try Writes.clear(anxiety.id, in: Writes.clear(sleep.id, in: skip, c), c)
        #expect(cleared.values.isEmpty)
        #expect(!cleared.values.keys.contains(sleep.id))
        // Clearing a blank changes nothing.
        let later = ctx(at("2027-07-22", 20))
        #expect(try Writes.clear(meds.id, in: set, later) == set)
    }

    @Test func skipRestFillsOnlyBlanksOfActiveTrackers() throws {
        let archived = Tracker(name: "Work", symbol: "briefcase.fill", type: .numeric, createdAt: day("2027-07-01"),
                               archivedRanges: [.init(from: day("2027-07-10"))])
        let notYet = Tracker(name: "Home", symbol: "house.fill", type: .numeric, createdAt: day("2027-07-23"))
        let c = ctx(at("2027-07-22", 9))
        let e = try Writes.set(7, for: sleep, in: nil, c)
        let rest = try Writes.skipRest(active: [sleep, anxiety, meds, archived, notYet], in: e, c)
        #expect(rest.values == [sleep.id: .set(7), anxiety.id: .skip, meds.id: .skip])
    }

    @Test func writeToClosedDayThrowsAndReturnsUnchanged() throws {
        let e = try Writes.set(7, for: sleep, in: nil, ctx(at("2027-07-22", 9)))
        let before = e
        let closed = ctx(at("2027-07-24", 9), status: .closed)
        #expect(throws: WriteError.dayClosed) { try Writes.set(5, for: sleep, in: e, closed) }
        #expect(throws: WriteError.dayClosed) { try Writes.skip(sleep, in: e, closed) }
        #expect(throws: WriteError.dayClosed) { try Writes.clear(sleep.id, in: e, closed) }
        #expect(throws: WriteError.dayClosed) { try Writes.setNote("x", in: e, closed) }
        #expect(throws: WriteError.dayClosed) { try Writes.skipRest(active: [anxiety], in: e, closed) }
        #expect(throws: WriteError.dayNotStarted) { try Writes.set(5, for: sleep, in: nil, ctx(at("2027-07-21", 9), status: .future)) }
        #expect(e == before)
    }

    @Test func writeOutsideActiveSpanRejected() {
        let archived = Tracker(name: "Work", symbol: "briefcase.fill", type: .numeric, createdAt: day("2027-07-01"),
                               archivedRanges: [.init(from: day("2027-07-10"), to: day("2027-07-30"))])
        let notYet = Tracker(name: "Home", symbol: "house.fill", type: .numeric, createdAt: day("2027-07-23"))
        let c = ctx(at("2027-07-22", 9))
        #expect(throws: WriteError.trackerNotActive) { try Writes.set(5, for: archived, in: nil, c) }
        #expect(throws: WriteError.trackerNotActive) { try Writes.skip(notYet, in: nil, c) }
    }

    @Test func valueOffStopGridRejected() throws {
        let c = ctx(at("2027-07-22", 9))
        for (tracker, bad) in [(sleep, 7.5), (sleep, -1), (sleep, 11), (anxiety, 3), (meds, 5), (sleep, .nan), (sleep, .infinity)] {
            #expect(throws: WriteError.valueOffScale) { try Writes.set(bad, for: tracker, in: nil, c) }
        }
        #expect(try Writes.set(7.5, for: anxiety, in: nil, c).values[anxiety.id] == .set(7.5))
        #expect(try Writes.set(10, for: meds, in: nil, c).values[meds.id] == .set(10))
    }

    @Test func noWriteEverCreatesAValueForAnotherTracker() throws {
        let c = ctx(at("2027-07-22", 9))
        #expect(try Writes.set(7, for: sleep, in: nil, c).values.keys.sorted { $0.uuidString < $1.uuidString } == [sleep.id])
        #expect(try Writes.skip(anxiety, in: nil, c).values == [anxiety.id: .skip])
        #expect(try Writes.setNote("n", in: nil, c).values.isEmpty)
        let both = try Writes.skip(anxiety, in: Writes.set(7, for: sleep, in: nil, c), c)
        #expect(try Writes.clear(sleep.id, in: both, c).values == [anxiety.id: .skip])
        #expect(try Writes.skipRest(active: [meds], in: both, c).values == [sleep.id: .set(7), anxiety.id: .skip, meds.id: .skip])
    }
}
