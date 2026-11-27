import DaytrackCore
import Foundation

/// One task at `DayClosing.nextBoundary`: the midnight relabel or the lock-hour close, whichever comes first.
/// `onBoundary` runs at each boundary and on every `refresh()`; the board holds it while a finger is down.
@MainActor
final class DayTicker {
    private let clock: Clock
    private let tz: TimeZone
    private let lockHour: () -> Int
    private let onBoundary: @MainActor () -> Void
    private var task: Task<Void, Never>?
    /// The boundary the pending task wakes at.
    private(set) var scheduledAt: Date?

    init(clock: Clock, tz: TimeZone, lockHour: @escaping () -> Int, onBoundary: @escaping @MainActor () -> Void) {
        (self.clock, self.tz, self.lockHour, self.onBoundary) = (clock, tz, lockHour, onBoundary)
    }

    /// Fires now and plans the next boundary. Call on appear and on every foreground.
    func refresh() {
        onBoundary()
        task?.cancel()
        let at = DayClosing.nextBoundary(now: clock.now, lockHour: lockHour(), tz: tz)
        let delay = at.timeIntervalSince(clock.now)
        scheduledAt = at
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled { self?.refresh() }
        }
    }
}
