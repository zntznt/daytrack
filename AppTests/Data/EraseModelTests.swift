import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor @Suite struct EraseModelTests {
    private struct FixedClock: Clock { let now: Date }

    @Test func eraseRemovesExportTempFiles() throws {
        let exports = FileManager.default.temporaryDirectory.appendingPathComponent("EraseExports-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: exports, withIntermediateDirectories: true)
        let left = exports.appendingPathComponent("daytrack-2027-07-22.json")
        try Data("{}".utf8).write(to: left)

        let store = InMemoryRecordStore()
        let recorder = Recorder(record: Record(trackers: [Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: DayKey("2027-07-01")!)]),
                                store: store, clock: FixedClock(now: Date()), widget: NoWidget(), reminders: NoReminders())
        let eraser = Eraser(recorder: recorder, store: store, deviceState: InMemoryDeviceStateStore(), reminders: NoReminders())
        try EraseModel(eraser: eraser, exportsDirectory: exports).erase()

        #expect(!FileManager.default.fileExists(atPath: exports.path))
        #expect(try store.load() == .empty)
    }
}
