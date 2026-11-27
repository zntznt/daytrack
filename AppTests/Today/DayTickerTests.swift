import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

private final class StepClock: Clock, @unchecked Sendable { var now: Date; init(_ now: Date) { self.now = now } }

@MainActor @Suite struct DayTickerTests {
    let tz = TimeZone(identifier: "Europe/London")!
    let today = DayKey("2027-03-10")!
    let store = InMemoryRecordStore()

    private func at(_ time: String) -> Date { ISO8601DateFormatter().date(from: "2027-03-10T\(time)Z")! }

    /// A board on 2027-03-10 with lock hour 20, and a ticker that drives it.
    private func board(_ clock: StepClock) -> (TodayModel, Recorder, DayTicker, Tracker) {
        let sleep = Tracker(name: "Sleep", symbol: "bed.double", type: .numeric, createdAt: today.adding(days: -10))
        let recorder = Recorder(record: Record(settings: Settings(lockHour: 20), trackers: [sleep]), store: store, clock: clock,
                                widget: NoWidget(), reminders: NoReminders(), tz: tz)
        let model = TodayModel(recorder: recorder, clock: clock, tz: tz)
        let ticker = DayTicker(clock: clock, tz: tz, lockHour: { recorder.record.settings.lockHour }, onBoundary: model.tick)
        return (model, recorder, ticker, sleep)
    }

    @Test func scheduledAtEarlierOfMidnightAndClose() {
        let clock = StepClock(at("10:00:00"))
        let (_, _, ticker, _) = board(clock)
        ticker.refresh()
        #expect(ticker.scheduledAt == at("20:00:00"))
        clock.now = at("21:00:00")
        ticker.refresh()
        #expect(ticker.scheduledAt == ISO8601DateFormatter().date(from: "2027-03-11T00:00:00Z"))
    }

    @Test func closeDeferredWhileDraggingFiresOnRelease() {
        let clock = StepClock(at("19:59:59"))
        let (model, recorder, ticker, sleep) = board(clock)
        ticker.refresh()
        model.isDragging = true
        clock.now = at("20:00:01")
        ticker.refresh()
        // Nothing moves under the finger: yesterday is not closed yet.
        #expect(recorder.record.settings.closedThrough == nil && model.record.settings.closedThrough == nil)
        model.commit(.set(6), to: sleep)
        model.isDragging = false
        #expect(model.record.settings.closedThrough == today.adding(days: -1))
        #expect(model.rows.first?.value == .set(6))
    }

    @Test func foregroundRefreshAdvancesClosedThrough() {
        let clock = StepClock(at("10:00:00"))
        let (model, recorder, ticker, _) = board(clock)
        ticker.refresh()
        // The app slept through the close and the midnight after it.
        clock.now = ISO8601DateFormatter().date(from: "2027-03-11T09:00:00Z")!
        ticker.refresh()
        #expect(recorder.record.settings.closedThrough == today.adding(days: -1))
        #expect(model.day == today.adding(days: 1))
        #expect(model.amendChip != nil)
        guard case .loaded(let saved) = try? store.load() else { Issue.record("nothing saved"); return }
        #expect(saved.settings.closedThrough == today.adding(days: -1))
    }
}
