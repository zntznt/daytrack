import Foundation
import Testing
@testable import DaytrackCore

@Suite struct ReminderCopyTests {
    @Test func scheduledForCopyShowsChosenTime() {
        #expect(Copy.reminderScheduled(.init(hour: 21, minute: 30)) == "scheduled for 21:30; delivery can still move it")
        #expect(Copy.reminderScheduled(.init(hour: 7, minute: 5)) == "scheduled for 07:05; delivery can still move it")
        #expect(Copy.reminderHorizon.contains("14 days"))
    }
}
