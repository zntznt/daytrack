import XCTest

final class EraseUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// A file store, so a relaunch reads what the erase left on disk.
    private let folder = "EraseUITests-\(UUID().uuidString)"

    private func launch(seed: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", folder, "-uiTestNow", "2027-03-10T10:00:00", "-uiTestTZ", "Europe/London",
                               "-uiTestScreen", "settings"] + (seed ? ["-uiTestSeed", "fortyDays"] : [])
        app.launch()
        return app
    }

    /// Settings › Data › Erase everything, then the confirm.
    private func askToErase(_ app: XCUIApplication) {
        let erase = app.buttons["settings.erase"]
        XCTAssertTrue(app.buttons["settings.lockHour"].waitForExistence(timeout: 10))
        for _ in 0..<3 where !erase.isHittable { app.swipeUp() }
        erase.tap()
        XCTAssertTrue(app.staticTexts["erase.confirm"].waitForExistence(timeout: 5))
    }

    func testConfirmShowsRealCounts() {
        let app = launch()
        askToErase(app)
        XCTAssertEqual(app.staticTexts["erase.confirm"].label, "40 days, 0 notes and 3 trackers. This cannot be undone.")
        app.buttons["erase.keep"].tap()
        XCTAssertTrue(app.buttons["settings.erase"].waitForExistence(timeout: 5))
    }

    func testEraseCopySaysSavedFilesUntouched() {
        let copy = "Daytrack keeps no other copy. Files you saved yourself are not touched; Daytrack cannot see them."
        let app = launch()
        askToErase(app)
        XCTAssertEqual(app.staticTexts["erase.noOtherCopy"].label, copy)
        app.buttons["erase.eraseAll"].tap()
        XCTAssertTrue(app.staticTexts["erased.noOtherCopy"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["erased.noOtherCopy"].label, copy)
    }

    func testAfterEraseOnboardingShowsAndRelaunchIsEmpty() {
        let app = launch()
        askToErase(app)
        app.buttons["erase.eraseAll"].tap()
        XCTAssertTrue(app.staticTexts["erased.title"].waitForExistence(timeout: 5))
        app.buttons["erased.startAgain"].tap()
        XCTAssertTrue(app.buttons["Pick your first sliders"].waitForExistence(timeout: 5))

        app.terminate()
        let again = launch(seed: false)
        XCTAssertTrue(again.buttons["Pick your first sliders"].waitForExistence(timeout: 10))
        XCTAssertFalse(again.tabBars.firstMatch.exists)
    }
}
