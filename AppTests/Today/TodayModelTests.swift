import DaytrackCore
import Foundation
import Testing
@testable import Daytrack

/// A clock the test moves by hand.
private final class StepClock: Clock, @unchecked Sendable { var now: Date; init(_ now: Date) { self.now = now } }

@MainActor @Suite struct TodayModelTests {
    let tz = TimeZone(identifier: "UTC")!
    let day = DayKey("2027-07-22")!
    private let clock = StepClock(ISO8601DateFormatter().date(from: "2027-07-22T10:00:00Z")!)
    let store = InMemoryRecordStore()

    private func model(_ trackers: [Tracker]) -> (TodayModel, Recorder) {
        let recorder = Recorder(record: Record(trackers: trackers), store: store, clock: clock, widget: NoWidget(),
                                reminders: NoReminders(), tz: tz)
        return (TodayModel(recorder: recorder, clock: clock, tz: tz), recorder)
    }

    private func tracker(_ name: String) -> Tracker { Tracker(name: name, symbol: "circle", type: .numeric, createdAt: day.adding(days: -10)) }

    @Test func updatesHeldWhileDraggingAppliedOnRelease() {
        let sleep = tracker("Sleep"), mood = tracker("Mood")
        let (board, recorder) = model([sleep, mood])
        board.isDragging = true
        board.commit(.set(6), to: sleep)
        var outside = recorder.record
        outside.trackers[1].name = "Mood renamed"
        board.receive(outside)
        // Stored at once, but the board does not move under the finger.
        #expect(recorder.record.entries[day]?.values[sleep.id] == .set(6))
        #expect(board.record.entries[day] == nil)
        #expect(board.rows.map(\.tracker.name) == ["Sleep", "Mood"])
        board.isDragging = false
        #expect(board.rows.map(\.value) == [.set(6), nil])
        #expect(board.rows.map(\.tracker.name) == ["Sleep", "Mood renamed"])
    }

    @Test func closedDayWriteLeavesStoredValue() throws {
        let sleep = tracker("Sleep")
        let (board, recorder) = model([sleep])
        board.commit(.set(4), to: sleep)
        let stored = try #require(recorder.record.entries[day])
        // Two days on, the day the board was opened for has closed.
        clock.now = clock.now.addingTimeInterval(2 * 86_400)
        board.commit(.set(9), to: sleep)
        board.commit(nil, to: sleep)
        board.skipRest()
        #expect(recorder.record.entries[day] == stored)
        guard case .loaded(let saved) = try store.load() else { Issue.record("nothing saved"); return }
        #expect(saved.entries[day] == stored)
        #expect(board.rows.first?.value == .set(4))
        #expect(!board.isOpen && board.skipRestTitle == nil)
    }
}
