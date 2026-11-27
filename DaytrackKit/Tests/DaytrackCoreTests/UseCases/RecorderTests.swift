import Foundation
import Testing
@testable import DaytrackCore

let useCaseTZ = TimeZone(identifier: "America/New_York")!

func useCaseAt(_ day: String, _ hour: Int, _ minute: Int = 0) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = useCaseTZ
    let d = DayKey(day)!
    return cal.date(from: DateComponents(year: d.year, month: d.month, day: d.day, hour: hour, minute: minute))!
}

/// Shared by every spy so tests can check the order of side effects.
final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String] = []
    func add(_ s: String) { lock.withLock { items.append(s) } }
    var events: [String] { lock.withLock { items } }
}

final class SpyRecordStore: RecordStore, @unchecked Sendable {
    let inner: InMemoryRecordStore
    let log: EventLog
    init(_ record: Record?, log: EventLog) { inner = InMemoryRecordStore(record); self.log = log }
    func load() throws -> LoadResult { try inner.load() }
    func save(_ record: Record) throws { log.add("save"); try inner.save(record) }
    var stored: Record? { if case .loaded(let r) = try? inner.load() { r } else { nil } }
}

final class SpySideEffects: WidgetPublishing, ReminderScheduling, @unchecked Sendable {
    let log: EventLog
    private let lock = NSLock()
    private(set) var published: [Record] = []
    private(set) var replanned: [Record] = []
    init(log: EventLog) { self.log = log }
    func publish(record: Record, now: Date) { log.add("publish"); lock.withLock { published.append(record) } }
    func replan(record: Record, now: Date) { log.add("replan"); lock.withLock { replanned.append(record) } }
    func removeAll() { log.add("removeAll") }
}

final class MutableClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date
    init(_ now: Date) { value = now }
    var now: Date {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}

let useCaseSleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: DayKey("2027-07-01")!)
let useCaseMeds = Tracker(name: "Meds taken", symbol: "pills.fill", type: .binary, createdAt: DayKey("2027-07-01")!)

struct Harness {
    let log = EventLog()
    let clock: MutableClock
    let store: SpyRecordStore
    let effects: SpySideEffects
    let recorder: Recorder

    init(_ record: Record = Record(trackers: [useCaseSleep, useCaseMeds]), now: Date) {
        clock = MutableClock(now)
        store = SpyRecordStore(record, log: log)
        effects = SpySideEffects(log: log)
        recorder = Recorder(record: record, store: store, clock: clock, widget: effects, reminders: effects, tz: useCaseTZ)
    }
}

private let d21 = DayKey("2027-07-21")!
private let d22 = DayKey("2027-07-22")!

@Suite struct RecorderTests {
    @Test func writeThenReloadPersists() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 9))
        try h.recorder.write(7, to: useCaseSleep.id, on: d22)
        try h.recorder.setNote("late night", on: d22)

        let reloaded = try #require(h.store.stored)
        #expect(reloaded == h.recorder.record)
        #expect(reloaded.entries[d22]?.values[useCaseSleep.id] == .set(7))
        #expect(reloaded.entries[d22]?.note == "late night")
    }

    @Test func writeAfterCloseRejectedStoreUntouched() throws {
        // Lock hour 23: the 21st closed at 23:00 on the 22nd.
        let h = Harness(now: useCaseAt("2027-07-22", 23, 30))
        let before = h.recorder.record
        #expect(throws: WriteError.dayClosed) { try h.recorder.write(7, to: useCaseSleep.id, on: d21) }
        #expect(throws: WriteError.dayClosed) { try h.recorder.skip(useCaseSleep.id, on: d21) }
        #expect(throws: WriteError.dayClosed) { try h.recorder.clear(useCaseSleep.id, on: d21) }
        #expect(throws: WriteError.dayClosed) { try h.recorder.setNote("x", on: d21) }
        #expect(throws: WriteError.dayClosed) { try h.recorder.skipRest(day: d21) }
        #expect(h.log.events.isEmpty)
        #expect(h.store.stored == before)
        #expect(h.recorder.record == before)
    }

    @Test func refreshAdvancesClosedThrough() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try h.recorder.refresh()
        #expect(h.store.stored?.settings.closedThrough == DayKey("2027-07-20"))
        h.clock.now = useCaseAt("2027-07-22", 23, 1)
        try h.recorder.refresh()
        #expect(h.store.stored?.settings.closedThrough == d21)
        #expect(h.effects.published.count == 2)
        #expect(h.effects.replanned.count == 2)
    }

    @Test func widgetPublishAndReminderReplanAfterWrite() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 9))
        try h.recorder.skip(useCaseMeds.id, on: d22)
        #expect(h.log.events == ["save", "publish", "replan"])
        #expect(h.effects.published == [h.store.stored!])
        #expect(h.effects.replanned == [h.store.stored!])
    }

    @Test func skipRestFillsOnlyBlanksAndSaves() throws {
        // Yesterday is still open at 10:00 under lock hour 23.
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try h.recorder.write(6, to: useCaseSleep.id, on: d21)
        try h.recorder.skipRest(day: d21)
        let entry = try #require(h.store.stored?.entries[d21])
        #expect(entry.values[useCaseSleep.id] == .set(6))
        #expect(entry.values[useCaseMeds.id] == .skip)
        #expect(entry.writtenNextDay)
        #expect(h.log.events == ["save", "publish", "replan", "save", "publish", "replan"])
    }

    @Test func clearRemovesValueAndUnknownTrackerThrows() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 9))
        try h.recorder.write(7, to: useCaseSleep.id, on: d22)
        try h.recorder.clear(useCaseSleep.id, on: d22)
        #expect(h.store.stored?.entries[d22]?.values[useCaseSleep.id] == nil)
        #expect(throws: WriteError.trackerNotActive) { try h.recorder.write(1, to: UUID(), on: d22) }
    }
}
