import Testing
@testable import DaytrackCore

@Suite struct SmokeTests {
    @Test func packageBuilds() {
        #expect(Bool(true))
    }
}
