import DaytrackCore
import Foundation
import Observation

/// The board's state. While a finger is down every update is held and applied on release,
/// so the board never re-renders under a moving finger (HANDOFF §4 "Two rules").
@MainActor @Observable
final class TodayModel {
    @ObservationIgnored private let recorder: Recorder
    @ObservationIgnored private let clock: Clock
    @ObservationIgnored private let tz: TimeZone
    @ObservationIgnored private var held: Record?
    /// The record the board shows.
    private(set) var record: Record
    /// shortcut: fixed at creation; the day turning on screen relabels to yesterday in M3.08.
    let day: DayKey

    @ObservationIgnored var isDragging = false {
        didSet {
            guard !isDragging, let held else { return }
            self.held = nil
            receive(held)
        }
    }

    init(recorder: Recorder, clock: Clock, tz: TimeZone) {
        self.recorder = recorder
        self.clock = clock
        self.tz = tz
        record = recorder.record
        day = LocalCalendar(timeZone: tz).dayKey(for: clock.now)
    }

    /// A newer record: shown now, or on release when a drag is live.
    func receive(_ next: Record) {
        if isDragging { held = next } else { record = next }
    }

    // MARK: Board

    /// One row per tracker active today, in roster order.
    var rows: [RowState] {
        let eras = Eras(record.revisions)
        let entry = record.entries[day], before = record.entries[day.adding(days: -1)]
        return record.trackers.filter { ActiveSpan.isActive($0, on: day) }.map { t in
            // trackWidth is a placeholder: the row measures its real track.
            RowState(tracker: t, value: entry?.values[t.id], yesterday: before?.values[t.id], trackWidth: 300,
                     mode: .drag, labels: eras.labels(t, on: day))
        }
    }

    var counts: RowCounts { RowCounts(entry: record.entries[day], day: day, trackers: record.trackers) }

    /// HANDOFF §9 boardEmpty: every tracker is archived.
    var isBoardEmpty: Bool { record.trackers.allSatisfy(\.isArchived) }

    /// Nothing has ever been written.
    var isDayOne: Bool { record.entries.isEmpty }

    var isOpen: Bool {
        let s = record.settings
        switch DayClosing.status(of: day, now: clock.now, lockHour: s.lockHour, closedThrough: s.closedThrough, tz: tz) {
        case .today, .yesterdayOpen: return true
        case .closed, .future: return false
        }
    }

    /// The weekday, in the user's locale and the record's zone.
    var dayName: String {
        var style = Date.FormatStyle.dateTime.weekday(.wide)
        style.timeZone = tz
        return LocalCalendar(timeZone: tz).startOfDay(day).formatted(style)
    }

    /// "Skip the rest of today"; nil when there is no blank left to fill or the day has closed.
    var skipRestTitle: String? {
        guard isOpen, counts.blank > 0, let label = Copy.dayLabel(for: day, now: clock.now, timeZone: tz) else { return nil }
        return Copy.skipRest(dayLabel: label)
    }

    // MARK: Writes

    /// Writes `value` (nil clears to blank) through `Recorder`.
    func commit(_ value: DayValue?, to tracker: Tracker) {
        apply {
            switch value {
            case .set(let v): try recorder.write(v, to: tracker.id, on: day)
            case .skip: try recorder.skip(tracker.id, on: day)
            case nil: try recorder.clear(tracker.id, on: day)
            }
        }
    }

    func skipRest() { apply { try recorder.skipRest(day: day) } }

    /// A refused write (the day closed, the tracker left the board) leaves the store untouched,
    /// so the board shows what is stored rather than what was attempted.
    private func apply(_ write: () throws -> Void) {
        try? write()
        receive(recorder.record)
    }
}
