import Foundation

public enum TrackerError: Error, Hashable, Sendable {
    /// Carries the line the disabled control announces (Q11a).
    case refused(String)
}

/// The only writer of tracker state. Every change goes through the Recorder pipeline.
public final class TrackerManager {
    private let recorder: Recorder
    private let calendar: LocalCalendar

    public init(recorder: Recorder, tz: TimeZone = .autoupdatingCurrent) {
        self.recorder = recorder
        self.calendar = LocalCalendar(timeZone: tz)
    }

    @discardableResult
    public func createFromCatalog(_ template: StarterTemplate) throws -> Tracker {
        try createCustom(name: template.name, symbol: template.symbol, type: template.type)
    }

    @discardableResult
    public func createCustom(name: String, symbol: String, type: TrackerType,
                             labels: [String]? = nil, anchors: Tracker.Anchors? = nil) throws -> Tracker {
        var made: Tracker!
        try recorder.commit { record, now in
            if case .refused(let reason) = Roster.canActivate(alongside: record.trackers) { throw TrackerError.refused(reason) }
            made = Tracker(name: name, symbol: symbol, type: type, labels: labels, anchors: anchors, createdAt: calendar.dayKey(for: now))
            record.trackers.append(made)
        }
        return made
    }

    /// Onboarding: only the picked starters become trackers; the rest stay a catalog (Q11b).
    public func startBoard(picked: [StarterTemplate]) throws {
        try recorder.commit { record, now in
            guard record.trackers.filter({ !$0.isArchived }).count + picked.count <= Roster.cap else {
                throw TrackerError.refused(Roster.fullRefusal)
            }
            let today = calendar.dayKey(for: now)
            record.trackers += picked.map { Tracker(name: $0.name, symbol: $0.symbol, type: $0.type, createdAt: today) }
        }
    }

    /// Stops asking from today. Every written day stays (HANDOFF §9).
    public func archive(_ id: UUID) throws {
        try change(id) { tracker, today in
            guard !tracker.isArchived else { return }
            tracker.archivedRanges.append(Tracker.ArchivedRange(from: today))
        }
    }

    /// Back on the board from today; refused at eight (Q11a).
    public func bringBack(_ id: UUID) throws {
        try recorder.commit { record, now in
            let i = Self.index(id, in: record)
            guard record.trackers[i].isArchived else { return }
            if case .refused(let reason) = Roster.canActivate(alongside: record.trackers) { throw TrackerError.refused(reason) }
            let today = calendar.dayKey(for: now)
            let last = record.trackers[i].archivedRanges.count - 1
            // Archived and brought back the same day: the range never covered a whole day.
            if record.trackers[i].archivedRanges[last].from >= today {
                record.trackers[i].archivedRanges.removeLast()
            } else {
                record.trackers[i].archivedRanges[last].to = today.adding(days: -1)
            }
        }
    }

    /// `order` must hold every tracker id exactly once.
    public func reorder(_ order: [UUID]) throws {
        try recorder.commit { record, _ in
            precondition(order.count == record.trackers.count && Set(order) == Set(record.trackers.map(\.id)), "order must list every tracker once")
            record.trackers = order.map { record.trackers[Self.index($0, in: record)] }
        }
    }

    public func rename(_ id: UUID, to name: String) throws {
        try change(id) { tracker, _ in tracker.name = name }
    }

    public func setSymbol(_ id: UUID, to symbol: String) throws {
        try change(id) { tracker, _ in tracker.symbol = symbol }
    }

    /// Free until a closed day holds a value; then a revision from today (Q6).
    public func editWording(_ id: UUID, labels: [String], anchors: Tracker.Anchors?) throws {
        try recorder.commit { record, now in
            record = try WordingEditRule.edit(id, labels: labels, anchors: anchors, in: record, today: calendar.dayKey(for: now))
        }
    }

    /// The real number of days, set or skipped, that `delete` would remove.
    public func deletePreview(_ id: UUID) -> Int {
        recorder.record.entries.values.filter { $0.values[id] != nil }.count
    }

    /// Removes the tracker, its values and its revisions. Already-made copies are unaffected.
    public func delete(_ id: UUID) throws {
        try recorder.commit { record, _ in
            record.trackers.remove(at: Self.index(id, in: record))
            record.revisions.removeAll { $0.trackerId == id }
            for day in record.entries.keys where record.entries[day]?.values[id] != nil {
                record.entries[day]?.values[id] = nil
            }
        }
    }

    private func change(_ id: UUID, _ apply: (inout Tracker, DayKey) -> Void) throws {
        try recorder.commit { record, now in
            apply(&record.trackers[Self.index(id, in: record)], calendar.dayKey(for: now))
        }
    }

    private static func index(_ id: UUID, in record: Record) -> Int {
        guard let i = record.trackers.firstIndex(where: { $0.id == id }) else { preconditionFailure("unknown tracker") }
        return i
    }
}
