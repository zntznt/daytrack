import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor @Suite struct DayOneWrittenTests {
    let today = DayKey("2027-07-22")!
    let sleep: Tracker, mood: Tracker

    init() {
        sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: today.adding(days: -10))
        mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: today.adding(days: -10))
    }

    private func record(_ day: DayKey, _ values: [UUID: DayValue]) -> Record {
        Record(trackers: [sleep, mood],
               entries: [day: DayEntry(date: day, values: values, firstWrittenAt: Date(), lastWrittenAt: Date(), tzOffsetAtWrite: 0)])
    }

    @Test func dayOneScreenShownOnlyOnce() {
        let store = InMemoryDeviceStateStore()
        let model = DayOneWrittenModel(deviceState: store)
        model.receive(Record(trackers: [sleep, mood]), today: today)
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
    }

    @Test func firstLaunchAfterAWrittenDayShows() {
        let model = DayOneWrittenModel(deviceState: InMemoryDeviceStateStore())
        model.receive(record(today.adding(days: -1), [sleep.id: .set(5)]), today: today)
        #expect(model.isShowing)
    }

    @Test func flagDefaultsOffAndOldFilesOpen() throws {
        let data = try JSONEncoder().encode(DeviceState(dayOneScreenShown: true))
        #expect(try JSONDecoder().decode(DeviceState.self, from: data).dayOneScreenShown)
        // An older file without the field still opens.
        #expect(try JSONDecoder().decode(DeviceState.self, from: Data("{}".utf8)) == DeviceState())
        #expect(!DeviceState().dayOneScreenShown)
    }
}
