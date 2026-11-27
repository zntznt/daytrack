import XCTest

final class TrackersUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(_ seed: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestSeed", seed, "-uiTestNow", "2027-03-10T10:00:00",
                               "-uiTestTZ", "Europe/London", "-uiTestLockHour", "20"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        return app
    }

    private func any(_ app: XCUIApplication, _ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }
    private let full = "Eight fit on one board. Archive one to make room."

    private func openTrackers(_ app: XCUIApplication) {
        app.tabBars.buttons["Settings"].tap()
        let link = app.buttons["settings.trackers"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertTrue(app.navigationBars["Trackers"].waitForExistence(timeout: 5))
    }

    private func archive(_ app: XCUIApplication, _ name: String) {
        let row = any(app, "trackers.row.\(name)")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Archive"].tap()
        XCTAssertTrue(row.waitForNonExistence(timeout: 5))
    }

    func testAddDisabledAtEightWithReason() {
        let app = launch("eightTrackers")
        openTrackers(app)
        let add = app.buttons["trackers.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertFalse(add.isEnabled)
        XCTAssertTrue(app.staticTexts[full].exists)

        // Room for one: add from the catalog, then the board is full again.
        archive(app, "Sleep")
        XCTAssertTrue(add.isEnabled)
        XCTAssertFalse(app.staticTexts[full].exists)
        add.tap()
        let eating = app.buttons["Eating"]
        XCTAssertTrue(eating.waitForExistence(timeout: 5))
        eating.tap()
        XCTAssertTrue(any(app, "trackers.row.Eating").waitForExistence(timeout: 5))
        XCTAssertFalse(add.isEnabled)

        // Bring-back is refused at eight with the same line.
        app.buttons["trackers.archived"].tap()
        let putBack = any(app, "archived.row.Sleep").buttons["Put back on Today"]
        XCTAssertTrue(putBack.waitForExistence(timeout: 5))
        XCTAssertFalse(putBack.isEnabled)
        XCTAssertTrue(app.staticTexts[full].exists)
    }

    func testArchiveRemovesRowKeepsDays() {
        let app = launch("fortyDays")
        openTrackers(app)
        archive(app, "Energy")
        XCTAssertTrue(any(app, "trackers.row.Sleep").exists)
        app.buttons["trackers.archived"].tap()
        XCTAssertTrue(any(app, "archived.row.Energy").waitForExistence(timeout: 5))

        // Off today's board, still on yesterday's with the value it wrote.
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(any(app, "track.Sleep").waitForExistence(timeout: 5))
        XCTAssertFalse(any(app, "track.Energy").exists)
        let chip = app.buttons["amendChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        chip.tap()
        let yesterday = any(app, "amend").descendants(matching: .any)["track.Energy"]
        XCTAssertTrue(yesterday.waitForExistence(timeout: 5))
        XCTAssertNotEqual(yesterday.value as? String, "not written yet")
    }

    func testBringOneBackFromBoardEmpty() {
        let app = launch("allArchived")
        let bringBack = app.buttons["Bring one back"]
        XCTAssertTrue(bringBack.waitForExistence(timeout: 5))
        bringBack.tap()
        XCTAssertTrue(app.navigationBars["Archived"].waitForExistence(timeout: 5))
        let putBack = any(app, "archived.row.Sleep").buttons["Put back on Today"]
        XCTAssertTrue(putBack.isEnabled)
        putBack.tap()
        XCTAssertTrue(any(app, "archived.row.Sleep").waitForNonExistence(timeout: 5))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(any(app, "track.Sleep").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Nothing on the board"].exists)
    }
}
