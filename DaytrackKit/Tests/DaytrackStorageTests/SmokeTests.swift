import Testing
@testable import DaytrackStorage

@Suite struct SmokeTests {
    @Test func packageBuilds() {
        #expect(Bool(true))
    }
}
