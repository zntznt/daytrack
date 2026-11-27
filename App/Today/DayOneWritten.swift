import DaytrackCore
import Foundation
import Observation

/// When the day-one-written screen shows ([O11]): once ever, when the first day's board has no blanks left,
/// or on the first launch after a day with anything written, whichever comes first.
/// Fed the board's record, which is held while a finger is down, so it never appears mid-drag.
@MainActor @Observable
final class DayOneWrittenModel {
    @ObservationIgnored private let deviceState: DeviceStateStore
    /// The flag is already set; nothing more to check this session.
    @ObservationIgnored private var done = false
    /// From the moment it shows until it is answered, this session only.
    private(set) var isShowing = false

    init(deviceState: DeviceStateStore) { self.deviceState = deviceState }

    func receive(_ record: Record, today: DayKey) {
        guard !done, var state = try? deviceState.load() else { return }
        guard !state.dayOneScreenShown else { done = true; return }
        guard Self.isDue(record, today: today) else { return }
        state.dayOneScreenShown = true
        try? deviceState.save(state)
        (done, isShowing) = (true, true)
    }

    func dismiss() { isShowing = false }

    static func isDue(_ record: Record, today: DayKey) -> Bool {
        // A reminder for a board with nothing on it would be asking about nothing (HANDOFF §9 boardEmpty).
        guard !record.trackers.allSatisfy(\.isArchived) else { return false }
        let written = record.entries.values.filter { !$0.values.isEmpty || $0.note != nil }.map(\.date)
        if written.contains(where: { $0 < today }) { return true }
        return written.contains(today) && RowCounts(entry: record.entries[today], day: today, trackers: record.trackers).blank == 0
    }
}
