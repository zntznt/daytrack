import XCTest

final class SaveCopyUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestSeed", "threeTrackersEmpty", "-uiTestNow", "2027-03-10T10:00:00",
                               "-uiTestTZ", "Europe/London", "-uiTestScreen", "settings"] + extra
        app.launch()
        return app
    }

    private func factLine(_ app: XCUIApplication) -> XCUIElement {
        let line = app.staticTexts["settings.lastFullCopy"]
        for _ in 0..<3 where !line.exists { app.swipeUp() }
        XCTAssertTrue(line.waitForExistence(timeout: 10))
        return line
    }

    func testFactLineSaysNoCopyYet() {
        let app = launch()
        XCTAssertEqual(factLine(app).label, "No copy saved yet")
    }

    @MainActor func testSaveCopyThenFactLineShowsToday() {
        let app = launch(["-uiTestExportTo", "SaveCopyUITests-\(UUID().uuidString)"])
        _ = factLine(app)
        app.buttons["settings.saveCopy"].tap()
        XCTAssertTrue(factLine(app).wait(for: \.label, toEqual: "Last full copy: 10 Mar (today)", timeout: 5))
        XCTAssertFalse(app.staticTexts["settings.saveCopyNotSaved"].exists)
    }

    /// The real exporter, not the direct write: it opens without crashing and cancels cleanly.
    func testRealExporterOpensAndCancels() {
        let app = launch()
        _ = factLine(app)
        app.buttons["settings.saveCopy"].tap()
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        XCTAssertEqual(app.state, .runningForeground)
        cancel.tap()
        XCTAssertTrue(app.staticTexts["settings.saveCopyNotSaved"].waitForExistence(timeout: 5))
    }
}
