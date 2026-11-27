import DaytrackCore
import Foundation
import Testing
@testable import DaytrackStorage

private func day(_ s: String) -> DayKey { DayKey(s)! }

private func tempDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("FileRecordStoreTests-\(UUID().uuidString)", isDirectory: true)
}

private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric, createdAt: day("2027-07-01"))
private let meds = Tracker(name: "Meds", symbol: "pills.fill", type: .binary, createdAt: day("2027-07-01"))
private let entry = DayEntry(date: day("2027-07-02"), values: [sleep.id: .set(7), meds.id: .skip], note: "Odd one",
                             firstWrittenAt: Date(timeIntervalSinceReferenceDate: 806_457_600.25),
                             lastWrittenAt: Date(timeIntervalSinceReferenceDate: 806_461_200.5), tzOffsetAtWrite: 3600)
private let sample = Record(settings: Settings(lockHour: 20, closedThrough: day("2027-07-01")), trackers: [sleep, meds],
                            entries: [entry.date: entry])

/// A fresh URL each time, so no cached resource value is read.
private func isExcluded(_ directory: URL) throws -> Bool {
    try URL(fileURLWithPath: directory.path).resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup ?? false
}

@Suite struct FileRecordStoreTests {
    @Test func saveThenLoadRoundTrips() throws {
        let store = FileRecordStore(directory: tempDirectory())
        try store.save(sample)
        #expect(try store.load() == .loaded(sample))
    }

    @Test func trackersWithoutDaysRoundTrip() throws {
        let store = FileRecordStore(directory: tempDirectory())
        var noDays = sample
        noDays.entries = [:]
        try store.save(noDays)
        #expect(try store.load() == .loaded(noDays))
        try store.save(Record())
        #expect(try store.load() == .loaded(Record()))
    }

    @Test func missingFileIsEmptyRecord() throws {
        #expect(try FileRecordStore(directory: tempDirectory()).load() == .empty)
    }

    @Test func directoryIsExcludedFromBackupAfterEverySave() throws {
        let directory = tempDirectory()
        let store = FileRecordStore(directory: directory)
        try store.save(sample)
        #expect(try isExcluded(directory))

        var cleared = URLResourceValues()
        cleared.isExcludedFromBackup = false
        var url = URL(fileURLWithPath: directory.path)
        try url.setResourceValues(cleared)
        #expect(try !isExcluded(directory))

        try store.save(sample)
        #expect(try isExcluded(directory))
    }

    @Test func unreadableFileMovedAsideNotOverwritten() throws {
        let directory = tempDirectory()
        let store = FileRecordStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let garbage = Data("{ not a record".utf8)
        try garbage.write(to: store.fileURL)

        guard case .unreadable(let kept) = try store.load() else { Issue.record("not reported unreadable"); return }
        #expect(kept.lastPathComponent.hasPrefix("record-unreadable-"))
        #expect(kept.pathExtension == "json")
        #expect(try Data(contentsOf: kept) == garbage)
        #expect(try store.load() == .empty)

        try store.save(sample)
        #expect(try Data(contentsOf: kept) == garbage)
        #expect(try store.load() == .loaded(sample))
    }

    @Test func noTempFileLeftAfterSave() throws {
        let directory = tempDirectory()
        let store = FileRecordStore(directory: directory)
        try store.save(sample)
        try store.save(sample)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["record.json"])
    }

    @Test func deviceStateNotInRecordFile() throws {
        let directory = tempDirectory()
        let records = FileRecordStore(directory: directory)
        let states = FileDeviceStateStore(directory: directory)
        #expect(try states.load() == DeviceState())

        let state = DeviceState(lastFullCopyAt: Date(timeIntervalSinceReferenceDate: 1), reportDraft: Data("draft".utf8),
                                remindersScheduledThrough: day("2027-07-14"))
        try states.save(state)
        try records.save(sample)

        #expect(try states.load() == state)
        let recordText = try String(contentsOf: records.fileURL, encoding: .utf8)
        for key in ["lastFullCopyAt", "reportDraft", "remindersScheduledThrough"] {
            #expect(!recordText.contains(key))
        }
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)) == ["record.json", "device.json"])
    }
}

extension FileRecordStoreTests {
    @Test func eraseAllRemovesUnreadableCopies() throws {
        let directory = tempDirectory()
        let store = FileRecordStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{ not a record".utf8).write(to: store.fileURL)
        guard case .unreadable = try store.load() else { Issue.record("not reported unreadable"); return }
        try store.save(sample)
        try FileDeviceStateStore(directory: directory).save(DeviceState(lastFullCopyAt: Date(timeIntervalSinceReferenceDate: 1)))
        let unrelated = directory.appendingPathComponent("notes.txt")
        try Data("not ours to judge".utf8).write(to: unrelated)

        try store.eraseAll()
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["notes.txt"])
        #expect(try store.load() == .empty)
        #expect(try FileDeviceStateStore(directory: directory).load() == DeviceState())
    }
}
