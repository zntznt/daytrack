import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor @Suite struct DayOneWrittenTests {
    let today = DayKey("2027-07-22")!
    let sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: DayKey("2027-07-01")!)
    let mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: DayKey("2027-07-01")!)

    private func record(_ day: DayKey, _ values: [UUID: DayValue]) -> Record {
        Record(trackers: [sleep, mood],
               entries: [day: DayEntry(date: day, values: values, firstWrittenAt: Date(), lastWrittenAt: Date(), tzOffsetAtWrite: 0)])
    }

    @Test func dayOneScreenShownOnlyOnce() {
        let store = InMemoryDeviceStateStore()
        let model = DayOneWrittenModel(deviceState: store)
        // A partly written first day is not yet day one.
        model.receive(record(today, [sleep.id: .set(5)]), today: today)
        #expect(!model.isShowing)
        model.receive(record(today, [sleep.id: .set(5), mood.id: .skip]), today: today)
        #expect(model.isShowing)
        #expect((try? store.load())?.dayOneScreenShown == true)
        model.dismiss()
        model.receive(record(today, [sleep.id: .set(5), mood.id: .skip]), today: today)
        #expect(!model.isShowing)
        // The next launch, after a written day: still not again.
        let relaunched = DayOneWrittenModel(deviceState: store)
        relaunched.receive(record(today.adding(days: -1), [sleep.id: .set(5)]), today: today)
        #expect(!relaunched.isShowing)
        // Erase saves a fresh DeviceState, and an older file without the flag opens with it off.
        let fresh = DayOneWrittenModel(deviceState: InMemoryDeviceStateStore(try! JSONDecoder().decode(DeviceState.self, from: Data("{}".utf8))))
        fresh.receive(record(today.adding(days: -1), [sleep.id: .set(5)]), today: today)
        #expect(fresh.isShowing)
    }
}
