import XCTest

final class NoteUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(now: String, store: String = "memory") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", store, "-uiTestSeed", "threeTrackersEmpty", "-uiTestNow", now,
                               "-uiTestTZ", "Europe/London", "-uiTestLockHour", "20"]
        app.launch()
        return app
    }

    private func element(_ root: XCUIElement, _ id: String) -> XCUIElement { root.descendants(matching: .any)[id] }

    private func openNote(_ root: XCUIElement) {
        let row = root.buttons["noteRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
    }

    private func openAmend(_ app: XCUIApplication) -> XCUIElement {
        let chip = app.buttons["amendChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        chip.tap()
        let board = element(app, "amend")
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        return board
    }

    func testNoteSavesWithoutButtonAndSurvivesRelaunch() {
        let store = UUID().uuidString
        var app = launch(now: "2027-03-10T10:00:00", store: store)
        openNote(app)
        let editor = app.textViews["noteEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // Tap once the sheet has settled: a tap mid-animation focuses nothing, and the editor's top runs under the nav bar.
        sleep(1)
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.typeText("Slept badly")
        // No Done, no dismiss: the debounced save alone must reach the store before the app dies.
        sleep(2)
        app.terminate()
        app = launch(now: "2027-03-10T10:00:00", store: store)
        let row = app.buttons["noteRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.contains("Slept badly"), row.label)
        row.tap()
        XCTAssertTrue(app.textViews["noteEditor"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textViews["noteEditor"].value as? String, "Slept badly")
    }

    func testNoteReadOnlyAfterClose() {
        let app = launch(now: "2027-03-10T19:59:40")
        let board = openAmend(app)
        openNote(board)
        let editor = app.textViews["noteEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // Yesterday closes at 20:00: the editor gives way to the note as written.
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: editor)
        wait(for: [gone], timeout: 30)
        XCTAssertEqual(element(app, "noteFooter").label, "Written with the day. It travels in every export.")
    }

    func testNoteFooterNamesCloseTime() {
        let app = launch(now: "2027-03-10T10:00:00")
        openNote(app)
        let footer = element(app, "noteFooter")
        XCTAssertTrue(footer.waitForExistence(timeout: 5))
        XCTAssertEqual(footer.label, "Editable until Thu 20:00, then it is written like the numbers.")
        app.buttons["Done"].tap()
        // Yesterday's note names the chip's close time (design-review Low 2).
        let chip = app.buttons["amendChip"].label
        XCTAssertEqual(chip, "until Wed 20:00")
        openNote(openAmend(app))
        XCTAssertTrue(footer.waitForExistence(timeout: 5))
        XCTAssertEqual(footer.label, "Editable \(chip), then it is written like the numbers.")
    }
}
