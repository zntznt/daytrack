import Foundation
import Testing
@testable import DaytrackCore

private func day(_ s: String) -> DayKey { DayKey(s)! }

private let sleep = Tracker(name: "Sleep", symbol: "moon.fill", type: .numeric,
                            anchors: .init(low: "Awful", high: "Rested"), createdAt: day("2027-07-01"))
private let anxiety = Tracker(name: "Anxiety", symbol: "wind", type: .ordinal, createdAt: day("2027-07-02"),
                              archivedRanges: [.init(from: day("2027-07-05"), to: day("2027-07-06")), .init(from: day("2027-07-09"))])
private let meds = Tracker(name: "Meds taken", symbol: "pills.fill", type: .binary, createdAt: day("2027-07-01"))

/// Sub-second instants, so the round trip must keep Date exactly.
private func instant(_ offset: Double) -> Date { Date(timeIntervalSinceReferenceDate: 806_457_600.123456789 + offset) }

func sampleRecord() -> Record {
    let revision = try! ScaleRevision(tracker: anxiety, effectiveFrom: day("2027-07-03"),
                                      previousLabels: ["None", "Some", "Mild", "Strong", "Severe"])
    let first = DayEntry(date: day("2027-07-02"), values: [sleep.id: .set(7), anxiety.id: .skip], note: "Long day, \"odd\" one",
                         firstWrittenAt: instant(0), lastWrittenAt: instant(3600.5), tzOffsetAtWrite: -14_400, writtenNextDay: true)
    let second = DayEntry(date: day("2027-07-03"), values: [anxiety.id: .set(7.5), meds.id: .set(10)],
                          firstWrittenAt: instant(86_400), lastWrittenAt: instant(86_401), tzOffsetAtWrite: 32_400,
                          origin: .import, importedAt: instant(1_000_000.25))
    return Record(settings: Settings(lockHour: 20, closedThrough: day("2027-07-02"), reminderAt: nil),
                  trackers: [sleep, anxiety, meds], revisions: [revision],
                  entries: [first.date: first, second.date: second])
}

private func json(_ s: String) -> Data { Data(s.utf8) }

@Suite struct CopyFileTests {
    @Test func roundTripIsLossless() throws {
        let data = try CopyFileCodec.encode(sampleRecord())
        guard case .copy(let decoded) = CopyFileCodec.decode(data) else { Issue.record("refused"); return }
        #expect(try CopyFileCodec.encode(decoded) == data)
        #expect(decoded.entries[day("2027-07-02")]?.lastWrittenAt == instant(3600.5))
        #expect(decoded.entries[day("2027-07-03")]?.origin == .import)
        #expect(decoded.entries[day("2027-07-02")]?.note == "Long day, \"odd\" one")
    }

    @Test func decodeOfEncodedRecordEqualsRecord() throws {
        let record = sampleRecord()
        #expect(CopyFileCodec.decode(try CopyFileCodec.encode(record)) == .copy(record))
        let defaults = Record(settings: Settings(), trackers: record.trackers, entries: record.entries)
        #expect(CopyFileCodec.decode(try CopyFileCodec.encode(defaults)) == .copy(defaults))
    }

    @Test func fileNameUsesLocalDate() {
        // 2027-07-23 03:30 UTC is still the 22nd in New York and already the 23rd in Tokyo.
        let late = Date(timeIntervalSince1970: 1_816_313_400)
        #expect(LocalCalendar(timeZone: TimeZone(identifier: "UTC")!).dayKey(for: late) == day("2027-07-23"))
        #expect(CopyFileCodec.fileName(on: late, timeZone: TimeZone(identifier: "America/New_York")!) == "daytrack-2027-07-22.json")
        #expect(CopyFileCodec.fileName(on: late, timeZone: TimeZone(identifier: "Asia/Tokyo")!) == "daytrack-2027-07-23.json")
    }

    @Test func notJSONRefusedWithReason() {
        #expect(CopyFileCodec.decode(json("date,Sleep\n2027-07-02,7\n")) == .refused(.notJSON))
        #expect(CopyFileCodec.decode(Data()) == .refused(.notJSON))
    }

    @Test func validJSONWithNoDaysRefusedWithReason() throws {
        let empty = try CopyFileCodec.encode(Record(trackers: [sleep]))
        #expect(CopyFileCodec.decode(empty) == .refused(.noDays))
        #expect(CopyFileCodec.decode(json(#"{"notes": ["a", "b"]}"#)) == .refused(.noDays))
        #expect(CopyFileCodec.decode(json("42")) == .refused(.noDays))
    }

    @Test func newerSchemaVersionRefused() throws {
        var object = try JSONSerialization.jsonObject(with: CopyFileCodec.encode(sampleRecord())) as! [String: Any]
        object["schemaVersion"] = 2
        #expect(CopyFileCodec.decode(try JSONSerialization.data(withJSONObject: object)) == .refused(.newerVersion(2)))
        #expect(CopyFileCodec.decode(json(#"{"schemaVersion": 7}"#)) == .refused(.newerVersion(7)))
    }

    @Test func missingCreatedAtTakesEarliestValueDate() throws {
        var object = try JSONSerialization.jsonObject(with: CopyFileCodec.encode(sampleRecord())) as! [String: Any]
        object["trackers"] = (object["trackers"] as! [[String: Any]]).map { var t = $0; t["createdAt"] = nil; return t }
        guard case .copy(let r) = CopyFileCodec.decode(try JSONSerialization.data(withJSONObject: object)) else {
            Issue.record("refused"); return
        }
        let createdAt = Dictionary(uniqueKeysWithValues: r.trackers.map { ($0.name, $0.createdAt) })
        #expect(createdAt["Sleep"] == day("2027-07-02"))
        #expect(createdAt["Anxiety"] == day("2027-07-02"))
        // Meds has no value on the 2nd; its earliest value is the 3rd.
        #expect(createdAt["Meds taken"] == day("2027-07-03"))
    }

    @Test func deviceOnlyFieldsNotExported() throws {
        let data = try CopyFileCodec.encode(sampleRecord())
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(Set(object.keys) == ["schemaVersion", "settings", "trackers", "revisions", "entries"])
        #expect(Set((object["settings"] as! [String: Any]).keys) == ["lockHour", "closedThrough"])
        let text = String(decoding: data, as: UTF8.self)
        for key in ["lastFullCopyAt", "reportDraft", "remindersScheduledThrough"] {
            #expect(!text.contains(key))
        }
    }

    @Test func malformedDaytrackFileRefusedNotCrashed() throws {
        var object = try JSONSerialization.jsonObject(with: CopyFileCodec.encode(sampleRecord())) as! [String: Any]
        object["trackers"] = (object["trackers"] as! [[String: Any]]).map { var t = $0; t["labels"] = ["One"]; return t }
        #expect(CopyFileCodec.decode(try JSONSerialization.data(withJSONObject: object)) == .refused(.noDays))
        var dup = try JSONSerialization.jsonObject(with: CopyFileCodec.encode(sampleRecord())) as! [String: Any]
        let entries = dup["entries"] as! [Any]
        dup["entries"] = entries + [entries[0]]
        #expect(CopyFileCodec.decode(try JSONSerialization.data(withJSONObject: dup)) == .refused(.noDays))
    }
}
