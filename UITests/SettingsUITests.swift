import XCTest

final class SettingsUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(now: String = "2027-03-10T10:00:00", lockHour: Int = 20) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestSeed", "threeTrackersEmpty", "-uiTestNow", now,
                               "-uiTestTZ", "Europe/London", "-uiTestLockHour", String(lockHour), "-uiTestScreen", "settings"]
        app.launch()
        return app
    }

    private func picker(_ app: XCUIApplication) -> XCUIElement {
        let picker = app.buttons["settings.lockHour"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        return picker
    }

    /// What the picker row says, label and value together.
    private func shown(_ app: XCUIApplication) -> String {
        let p = picker(app)
        return "\(p.label) \(p.value as? String ?? "")"
    }

    /// The hour list stays pushed when a pick changed nothing; go back to the Settings list.
    private func backToSettings(_ app: XCUIApplication) {
        let bar = app.navigationBars["Yesterday stays open until"]
        if bar.waitForExistence(timeout: 2) { bar.buttons.element(boundBy: 0).tap() }
    }

    private func pick(_ app: XCUIApplication, _ hour: String) {
        let option = app.buttons[hour]
        picker(app).tap()
        XCTAssertTrue(app.navigationBars["Yesterday stays open until"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !(option.exists && option.isHittable) { app.swipeUp() }
        option.tap()
    }

    private func amendChip(_ app: XCUIApplication) -> XCUIElement {
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["track.Sleep"].waitForExistence(timeout: 10))
        return app.buttons["amendChip"]
    }

    func testTrackersIsFirstRow() {
        let app = launch()
        let trackers = app.buttons["settings.trackers"]
        XCTAssertTrue(trackers.waitForExistence(timeout: 10))
        XCTAssertLessThan(trackers.frame.minY, picker(app).frame.minY)
        let version = app.descendants(matching: .any)["settings.version"]
        XCTAssertTrue(version.exists)
        XCTAssertLessThan(picker(app).frame.minY, version.frame.minY)
    }

    func testLockHourZeroLabelSaysNoGraceDay() {
        let app = launch(lockHour: 0)
        XCTAssertTrue(shown(app).contains("Yesterday stays open until"))
        XCTAssertTrue(shown(app).contains("00:00 · no grace day"))
    }

    func testLoweringBelowNowAsksConfirm() {
        let app = launch()
        pick(app, "09:00")
        let close = app.buttons["Close yesterday"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        backToSettings(app)
        XCTAssertTrue(shown(app).contains("09:00"))
        XCTAssertFalse(amendChip(app).exists)
    }

    func testCancelledLoweringKeepsYesterdayOpen() {
        let app = launch()
        pick(app, "09:00")
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        backToSettings(app)
        XCTAssertTrue(shown(app).contains("20:00"))
        let chip = amendChip(app)
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertEqual(chip.label, "until Wed 20:00")
    }

    func testRaisingLockHourNeverReopensClosedDay() {
        // 10:00 with lock hour 9: yesterday closed at 09:00 today.
        let app = launch(lockHour: 9)
        pick(app, "22:00")
        XCTAssertFalse(app.buttons["Close yesterday"].waitForExistence(timeout: 2))
        backToSettings(app)
        XCTAssertTrue(shown(app).contains("22:00"))
        XCTAssertFalse(amendChip(app).exists)
    }
}
