import Foundation
import Testing
@testable import DaytrackCore

private let d21 = DayKey("2027-07-21")!

@Suite struct SettingsServiceTests {
    private func service(_ h: Harness, _ states: DeviceStateStore = InMemoryDeviceStateStore()) -> SettingsService {
        SettingsService(recorder: h.recorder, deviceState: states)
    }

    @Test func loweringLockHourNeedsConfirmWhileYesterdayOpen() throws {
        // 10:00 on the 22nd: the 21st is open until 23:00.
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        let before = h.recorder.record
        #expect(try service(h).setLockHour(8) == .needsConfirm)
        #expect(h.recorder.record == before)
        #expect(h.log.events.isEmpty)
        // A lower hour that has not passed yet closes nothing.
        #expect(try service(h).setLockHour(12) == .applied)
        #expect(h.store.stored?.settings.lockHour == 12)
        #expect(h.store.stored?.settings.closedThrough == DayKey("2027-07-20"))
    }

    @Test func confirmedLoweringClosesYesterday() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try service(h).confirmLockHour(8)
        #expect(h.store.stored?.settings.lockHour == 8)
        #expect(h.store.stored?.settings.closedThrough == d21)
        #expect(h.log.events == ["save", "publish", "replan"])
        #expect(throws: WriteError.dayClosed) { try h.recorder.write(7, to: useCaseSleep.id, on: d21) }
    }

    @Test func raisingLockHourKeepsClosedThrough() throws {
        // Lock hour 8 at 10:00: the 21st is already closed.
        let h = Harness(Record(settings: Settings(lockHour: 8), trackers: [useCaseSleep]), now: useCaseAt("2027-07-22", 10))
        try h.recorder.refresh()
        #expect(h.store.stored?.settings.closedThrough == d21)
        #expect(try service(h).setLockHour(23) == .applied)
        #expect(h.store.stored?.settings.lockHour == 23)
        #expect(h.store.stored?.settings.closedThrough == d21)
        #expect(throws: WriteError.dayClosed) { try h.recorder.write(7, to: useCaseSleep.id, on: d21) }
    }

    @Test func reminderAtSavesAndReplans() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        try service(h).setReminderAt(Settings.ReminderTime(hour: 20, minute: 15))
        #expect(h.store.stored?.settings.reminderAt == Settings.ReminderTime(hour: 20, minute: 15))
        try service(h).setReminderAt(nil)
        #expect(h.store.stored?.settings.reminderAt == nil)
        #expect(h.effects.replanned.count == 2)
    }

    @Test func fullCopySavedWritesDeviceStateOnly() throws {
        let h = Harness(now: useCaseAt("2027-07-22", 10))
        let states = InMemoryDeviceStateStore(DeviceState(remindersScheduledThrough: DayKey("2027-08-01")))
        let at = useCaseAt("2027-07-22", 10, 5)
        try service(h, states).recordFullCopySaved(at: at)
        #expect(try states.load() == DeviceState(lastFullCopyAt: at, remindersScheduledThrough: DayKey("2027-08-01")))
        #expect(h.log.events.isEmpty)
        #expect(h.store.stored == Record(trackers: [useCaseSleep, useCaseMeds]))
    }
}
