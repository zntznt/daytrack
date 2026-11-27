import DaytrackCore
import Foundation

/// `record.json` in an injected directory, in the copy-file schema (Q2).
/// shortcut: whole-file rewrite per save, move to SQLite past ~5 MB.
public struct FileRecordStore: RecordStore {
    public let directory: URL

    public init(directory: URL) { self.directory = directory }

    var fileURL: URL { directory.appendingPathComponent("record.json") }

    public func load() throws -> LoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        let data = try Data(contentsOf: fileURL)
        if let record = Self.decode(data) { return .loaded(record) }
        // Colons dropped so the name is safe in Files and Finder.
        let stamp = Date().formatted(.iso8601).replacingOccurrences(of: ":", with: "")
        let kept = directory.appendingPathComponent("record-unreadable-\(stamp).json")
        try FileManager.default.moveItem(at: fileURL, to: kept)
        return .unreadable(keptAt: kept)
    }

    public func save(_ record: Record) throws {
        try StoreFile.write(try CopyFileCodec.encode(record), to: fileURL)
    }

    /// `record.json`, `device.json` and every `record-unreadable-*.json`: a kept copy would make the Erase copy false (M3.12).
    public func eraseAll() throws {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        for name in names where name == "record.json" || name == "device.json" || name.hasPrefix("record-unreadable-") {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    static func decode(_ data: Data) -> Record? {
        switch CopyFileCodec.decode(data) {
        case .copy(let record): record
        case .refused(.noDays): decodeWithoutDays(data)
        case .refused: nil
        }
    }

    /// The codec refuses a file with no days (a restore rule), but the store must keep trackers saved before day one.
    /// shortcut: decodes with one placeholder day and drops it; replace with a codec entry point that allows no days.
    private static func decodeWithoutDays(_ data: Data) -> Record? {
        guard var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              (object["entries"] as? [Any])?.isEmpty == true
        else { return nil }
        let placeholder = DayKey(year: 1, month: 1, day: 1)!
        object["entries"] = [[
            "date": placeholder.isoString, "values": [String: Any](), "firstWrittenAt": 0, "lastWrittenAt": 0,
            "tzOffsetAtWrite": 0, "writtenNextDay": false, "origin": "device",
        ] as [String: Any]]
        guard let patched = try? JSONSerialization.data(withJSONObject: object),
              case .copy(var record) = CopyFileCodec.decode(patched)
        else { return nil }
        record.entries[placeholder] = nil
        return record
    }
}

/// `device.json`, beside the record but never inside it (Q2, Q7b).
public struct FileDeviceStateStore: DeviceStateStore {
    public let directory: URL

    public init(directory: URL) { self.directory = directory }

    var fileURL: URL { directory.appendingPathComponent("device.json") }

    public func load() throws -> DeviceState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return DeviceState() }
        return try JSONDecoder().decode(DeviceState.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ state: DeviceState) throws {
        try StoreFile.write(try JSONEncoder().encode(state), to: fileURL)
    }
}

enum StoreFile {
    /// Atomic, and readable after first unlock so a background notification action can write.
    /// The directory is re-marked excluded from backup on every save (Q8, rule 1).
    static func write(_ data: Data, to url: URL) throws {
        var directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }
}
