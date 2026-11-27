import XCTest

final class ChoicePadUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Sleep (numeric) blank, Anxiety (ordinal) "Mild", Meds taken (binary) skipped. `pad.last` records the key the pad reported.
    private func launchPad() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestScreen", "choicePad"]
        app.launch()
        XCTAssertTrue(app.staticTexts["pad.last"].waitForExistence(timeout: 10))
        return app
    }

    private func openPad(_ app: XCUIApplication, _ label: String, expecting key: String) {
        app.buttons[label].tap()
        XCTAssertTrue(app.buttons[key].waitForExistence(timeout: 5))
    }

    private func last(_ app: XCUIApplication) -> String {
        app.staticTexts["pad.last"].label
    }

    func testTapValueOpensPad() {
        let app = launchPad()
        openPad(app, "Anxiety, Mild. Activate for choices", expecting: "Skip Anxiety")
        XCTAssertTrue(app.buttons["Moderate"].exists)
        XCTAssertTrue(app.buttons["Leave Anxiety blank"].exists)
        XCTAssertEqual(last(app), "none")
    }

    func testSkipKeyReportsSkipNotBlank() {
        let app = launchPad()
        openPad(app, "Anxiety, Mild. Activate for choices", expecting: "Skip Anxiety")
        app.buttons["Skip Anxiety"].tap()
        XCTAssertEqual(last(app), "skip")
        XCTAssertTrue(app.buttons["Anxiety, skipped. Activate for choices"].waitForExistence(timeout: 5))
    }

    func testLeaveBlankHiddenWhenBlank() {
        let app = launchPad()
        openPad(app, "Sleep, not written yet. Activate for choices", expecting: "Skip Sleep")
        XCTAssertFalse(app.buttons["Leave Sleep blank"].exists)
    }

    func testLeaveBlankReportsClear() {
        let app = launchPad()
        openPad(app, "Meds taken, skipped. Activate for choices", expecting: "Leave Meds taken blank")
        app.buttons["Leave Meds taken blank"].tap()
        XCTAssertEqual(last(app), "blank")
        XCTAssertTrue(app.buttons["Meds taken, not written yet. Activate for choices"].waitForExistence(timeout: 5))
    }

    func testPadClosesOnCommit() {
        let app = launchPad()
        openPad(app, "Anxiety, Mild. Activate for choices", expecting: "Skip Anxiety")
        app.buttons["Moderate"].tap()
        // No transition: the pad is gone as soon as the key reports.
        XCTAssertFalse(app.buttons["Skip Anxiety"].exists)
        XCTAssertTrue(app.buttons["Anxiety, Moderate. Activate for choices"].exists)
        XCTAssertTrue(last(app).hasPrefix("set "))
    }
}
