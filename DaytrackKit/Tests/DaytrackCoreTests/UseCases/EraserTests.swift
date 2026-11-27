import Foundation
import Testing
@testable import DaytrackCore

private let d20 = DayKey("2027-07-20")!
private let d21 = DayKey("2027-07-21")!

private func entry(_ day: DayKey, _ values: [UUID: DayValue], note: String? = nil) -> DayEntry {
    let at = useCaseAt(day.isoString, 20)
    return DayEntry(date: day, values: values, note: note, firstWrittenAt: at, lastWrittenAt: at, tzOffsetAtWrite: 0)
}

private let full = Record(settings: Settings(lockHour: 20, closedThrough: d21, reminderAt: nil), trackers: [useCaseSleep, useCaseMeds],
                          entries: [d20: entry(d20, [useCaseSleep.id: .set(7)], note: "Late"), d21: entry(d21, [useCaseMeds.id: .skip])])

private func harness() -> (Harness, InMemoryDeviceStateStore, Eraser) {
    let h = Harness(full, now: useCaseAt("2027-07-22", 9))
    let device = InMemoryDeviceStateStore(DeviceState(lastFullCopyAt: Date(timeIntervalSinceReferenceDate: 1), reportDraft: Data("draft".utf8),
                                                      remindersScheduledThrough: d21))
    return (h, device, Eraser(recorder: h.recorder, store: h.store.inner, deviceState: device, reminders: h.effects))
}

@Suite struct EraserTests {
    @Test func eraseClearsRecordSettingsDeviceState() throws {
        let (h, device, eraser) = harness()
        try eraser.eraseAll()
        #expect(try h.store.inner.load() == .empty)
        #expect(h.recorder.record == Record())
        #expect(h.recorder.record.settings.closedThrough == nil)
        #expect(try device.load() == DeviceState())
    }

    @Test func eraseRemovesPendingRemindersAndRepublishesWidget() throws {
        let (h, _, eraser) = harness()
        try eraser.eraseAll()
        #expect(h.effects.published == [Record()])
        #expect(h.log.events.last == "removeAll")
    }

    @Test func confirmCountsAreReal() {
        #expect(Copy.eraseConfirm(full) == "2 days, 1 note and 2 trackers. This cannot be undone.")
        var one = full
        one.entries[d21] = entry(d21, [:])
        one.trackers.removeLast()
        #expect(Copy.eraseConfirm(one) == "1 day, 1 note and 1 tracker. This cannot be undone.")
        #expect(Copy.eraseConfirm(Record()) == "0 days, 0 notes and 0 trackers. This cannot be undone.")
    }
}
