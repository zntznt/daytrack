import Foundation
import Testing
@testable import DaytrackCore

@Suite struct InMemoryTests {
    @Test func inMemoryStoreRoundTrips() throws {
        let store = InMemoryRecordStore()
        #expect(try store.load() == .empty)
        let record = Record(trackers: [Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: DayKey("2027-07-01")!)])
        try store.save(record)
        #expect(try store.load() == .loaded(record))

        let states = InMemoryDeviceStateStore()
        #expect(try states.load() == DeviceState())
        let state = DeviceState(lastFullCopyAt: Date(timeIntervalSinceReferenceDate: 1), remindersScheduledThrough: DayKey("2027-07-14"))
        try states.save(state)
        #expect(try states.load() == state)
    }
}
