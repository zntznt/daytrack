import Foundation

/// The full copy and the on-device record share this one schema (Q2, M2.01).
/// DeviceState (lastFullCopyAt, reportDraft, remindersScheduledThrough) is never part of it.
public enum CopyFileCodec {
    public static let schemaVersion = 1

    public enum Refusal: Hashable, Sendable {
        case notJSON
        /// Read fine, but holds no Daytrack days (HANDOFF §8).
        case noDays
        case newerVersion(Int)
    }

    public enum Decoded: Hashable, Sendable {
        case copy(Record)
        case refused(Refusal)
    }

    /// `daytrack-YYYY-MM-DD.json`, dated on the local calendar.
    public static func fileName(on date: Date, timeZone: TimeZone = .current) -> String {
        "daytrack-\(LocalCalendar(timeZone: timeZone).dayKey(for: date).isoString).json"
    }

    public static func encode(_ record: Record) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(FileV1(record))
    }

    public static func decode(_ data: Data) -> Decoded {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else {
            return .refused(.notJSON)
        }
        if let version = (object as? [String: Any])?["schemaVersion"] as? Int, version > schemaVersion {
            return .refused(.newerVersion(version))
        }
        guard let file = try? JSONDecoder().decode(FileV1.self, from: data),
              file.schemaVersion == schemaVersion, !file.entries.isEmpty,
              let record = file.record()
        else { return .refused(.noDays) }
        return .copy(record)
    }
}

// Dates use JSONEncoder's default (seconds since the reference date) because it round-trips a Date exactly.
private struct FileV1: Codable {
    struct TrackerV1: Codable {
        var id: UUID
        var name: String
        var symbol: String
        var type: TrackerType
        var labels: [String]
        var anchors: Tracker.Anchors?
        /// Optional on read: older files may lack it (Q11b amendment 2).
        var createdAt: DayKey?
        var archivedRanges: [Tracker.ArchivedRange]
    }

    struct RevisionV1: Codable {
        var trackerId: UUID
        var effectiveFrom: DayKey
        var previousLabels: [String]
        var previousAnchors: Tracker.Anchors?
    }

    /// A number (canonical 0–10) or the string "skip". Blank has no cell at all.
    struct ValueV1: Codable {
        var value: DayValue

        init(_ value: DayValue) { self.value = value }

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let n = try? c.decode(Double.self) {
                guard (0...10).contains(n) else {
                    throw DecodingError.dataCorruptedError(in: c, debugDescription: "value outside 0–10")
                }
                value = .set(n)
            } else if try c.decode(String.self) == "skip" {
                value = .skip
            } else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "not a value")
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch value {
            case .set(let n): try c.encode(n)
            case .skip: try c.encode("skip")
            }
        }
    }

    struct EntryV1: Codable {
        var date: DayKey
        var values: [String: ValueV1]
        var note: String?
        var firstWrittenAt: Date
        var lastWrittenAt: Date
        var tzOffsetAtWrite: Int
        var writtenNextDay: Bool
        var origin: String
        var importedAt: Date?
    }

    var schemaVersion: Int
    var settings: Settings
    var trackers: [TrackerV1]
    var revisions: [RevisionV1]
    var entries: [EntryV1]

    init(_ r: Record) {
        schemaVersion = CopyFileCodec.schemaVersion
        settings = r.settings
        trackers = r.trackers.map {
            TrackerV1(id: $0.id, name: $0.name, symbol: $0.symbol, type: $0.type, labels: $0.labels,
                      anchors: $0.anchors, createdAt: $0.createdAt, archivedRanges: $0.archivedRanges)
        }
        revisions = r.revisions.map {
            RevisionV1(trackerId: $0.trackerId, effectiveFrom: $0.effectiveFrom,
                       previousLabels: $0.previousLabels, previousAnchors: $0.previousAnchors)
        }
        entries = r.entries.values.sorted { $0.date < $1.date }.map { e in
            EntryV1(date: e.date, values: Dictionary(uniqueKeysWithValues: e.values.map { ($0.key.uuidString, ValueV1($0.value)) }),
                    note: e.note, firstWrittenAt: e.firstWrittenAt, lastWrittenAt: e.lastWrittenAt,
                    tzOffsetAtWrite: e.tzOffsetAtWrite, writtenNextDay: e.writtenNextDay,
                    origin: e.origin.rawValue, importedAt: e.importedAt)
        }
    }

    /// nil when the file breaks an invariant the domain types assume.
    func record() -> Record? {
        guard (0...23).contains(settings.lockHour) else { return nil }

        var days: [DayKey: DayEntry] = [:]
        for e in entries {
            guard days[e.date] == nil, let origin = DayEntry.Origin(rawValue: e.origin) else { return nil }
            var values: [UUID: DayValue] = [:]
            for (key, cell) in e.values {
                guard let id = UUID(uuidString: key) else { return nil }
                values[id] = cell.value
            }
            days[e.date] = DayEntry(date: e.date, values: values, note: e.note,
                                    firstWrittenAt: e.firstWrittenAt, lastWrittenAt: e.lastWrittenAt,
                                    tzOffsetAtWrite: e.tzOffsetAtWrite, writtenNextDay: e.writtenNextDay,
                                    origin: origin, importedAt: e.importedAt)
        }
        guard let firstDay = days.keys.min() else { return nil }

        var built: [Tracker] = []
        for t in trackers {
            guard t.labels.count == (t.type == .numeric ? 0 : t.type.stops),
                  !built.contains(where: { $0.id == t.id })
            else { return nil }
            // shortcut: a tracker with no values and no createdAt falls back to the file's first day; owner to confirm.
            let createdAt = t.createdAt ?? days.values.filter { $0.values[t.id] != nil }.map(\.date).min() ?? firstDay
            built.append(Tracker(id: t.id, name: t.name, symbol: t.symbol, type: t.type, labels: t.labels,
                                 anchors: t.anchors, createdAt: createdAt, archivedRanges: t.archivedRanges))
        }

        var revs: [ScaleRevision] = []
        for r in revisions {
            guard let tracker = built.first(where: { $0.id == r.trackerId }),
                  let rev = try? ScaleRevision(tracker: tracker, effectiveFrom: r.effectiveFrom,
                                               previousLabels: r.previousLabels, previousAnchors: r.previousAnchors)
            else { return nil }
            revs.append(rev)
        }

        return Record(settings: settings, trackers: built, revisions: revs, entries: days)
    }
}
