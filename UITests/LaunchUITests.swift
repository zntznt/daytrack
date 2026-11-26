import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAppLaunchesShowingName() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Daytrack"].waitForExistence(timeout: 10))
    }

    func testWindowFillsScreen() {
        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertEqual(window.frame.height, springboard.frame.height)
    }
}
