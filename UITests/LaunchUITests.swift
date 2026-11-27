import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory"] + arguments
        app.launch()
        return app
    }

    func testAppLaunchesShowingName() {
        let app = launch([])
        XCTAssertTrue(app.staticTexts["Daytrack"].waitForExistence(timeout: 10))
    }

    func testWindowFillsScreen() {
        let app = launch([])
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertEqual(window.frame.height, springboard.frame.height)
    }

    func testTabsAreTodayAndSettings() {
        let app = launch(["-uiTestSeed", "threeTrackersEmpty"])
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(tabs.allElementsBoundByIndex.map { $0.label }, ["Today", "Settings"])
    }

    func testUITestClockArgumentShowsGivenDay() {
        let app = launch(["-uiTestSeed", "threeTrackersEmpty", "-uiTestNow", "2027-03-10T23:30:00", "-uiTestTZ", "America/New_York"])
        XCTAssertTrue(app.staticTexts["2027-03-10"].waitForExistence(timeout: 10))
    }
}
