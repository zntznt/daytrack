import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

@MainActor @Suite struct SaveCopyModelTests {
    let tz = TimeZone(identifier: "UTC")!
    let day = DayKey("2027-07-22")!
    let now = ISO8601DateFormatter().date(from: "2027-07-22T10:00:00Z")!
    let deviceState = InMemoryDeviceStateStore()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SaveCopy-\(UUID().uuidString)", isDirectory: true)

    private struct FixedClock: Clock { let now: Date }

    let record: Record

    init() {
        let sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: day.adding(days: -10))
        let yesterday = day.adding(days: -1)
        let entry = DayEntry(date: yesterday, values: [sleep.id: .set(7)], note: "A note",
                             firstWrittenAt: now.addingTimeInterval(-86_400), lastWrittenAt: now.addingTimeInterval(-86_400), tzOffsetAtWrite: 0)
        record = Record(trackers: [sleep], entries: [yesterday: entry])
    }

    private func model() -> SaveCopyModel {
        let clock = FixedClock(now: now)
        let recorder = Recorder(record: record, store: InMemoryRecordStore(), clock: clock, widget: NoWidget(), reminders: NoReminders(), tz: tz)
        return SaveCopyModel(settings: SettingsService(recorder: recorder, deviceState: deviceState), deviceState: deviceState,
                             clock: clock, timeZone: tz, directory: directory)
    }

    @Test func fileWrittenLocallyBeforeExporterShown() throws {
        let copy = model()
        #expect(copy.pending == nil)
        copy.prepare(record)
        let url = try #require(copy.pending)
        #expect(url.lastPathComponent == "daytrack-2027-07-22.json")
        #expect(url.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test func successUpdatesLastFullCopyAt() throws {
        let copy = model()
        copy.prepare(record)
        copy.finish(saved: true)
        #expect(try deviceState.load().lastFullCopyAt == now)
        #expect(copy.lastFullCopyAt == now)
        #expect(!copy.notSaved)
    }

    @Test func cancelLeavesLastFullCopyUnchanged() throws {
        let earlier = now.addingTimeInterval(-11 * 86_400)
        try deviceState.save(DeviceState(lastFullCopyAt: earlier))
        let copy = model()
        copy.prepare(record)
        copy.finish(saved: false)
        #expect(try deviceState.load().lastFullCopyAt == earlier)
        #expect(copy.lastFullCopyAt == earlier)
        #expect(copy.notSaved)
        // The line stays until the next attempt.
        copy.prepare(record)
        #expect(!copy.notSaved)
    }

    @Test func exportedDataDecodesLosslessly() throws {
        let copy = model()
        copy.prepare(record)
        let data = try Data(contentsOf: try #require(copy.pending))
        #expect(CopyFileCodec.decode(data) == .copy(record))
    }

    @Test func tempFileDeletedWhenExporterCloses() throws {
        for saved in [true, false] {
            let copy = model()
            copy.prepare(record)
            let url = try #require(copy.pending)
            copy.finish(saved: saved)
            #expect(copy.pending == nil)
            #expect(!FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test func exportsDirPurgedOnLaunch() throws {
        let dir = AppEnvironment.exportsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let left = dir.appendingPathComponent("daytrack-2027-07-21.json")
        try Data("{}".utf8).write(to: left)
        _ = AppEnvironment.launch()
        #expect(!FileManager.default.fileExists(atPath: left.path))
    }
}
