import Testing
@testable import Daytrack

@Suite struct SmokeTests {
    @Test func appModuleLoads() {
        #expect(String(describing: DaytrackApp.self) == "DaytrackApp")
    }
}
