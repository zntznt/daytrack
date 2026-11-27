import XCTest

final class AmendUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(now: String, lockHour: Int = 20, store: String = "memory") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", store, "-uiTestSeed", "threeTrackersEmpty", "-uiTestNow", now,
                               "-uiTestTZ", "Europe/London", "-uiTestLockHour", String(lockHour)]
        app.launch()
        return app
    }

    private func chip(_ app: XCUIApplication) -> XCUIElement { app.buttons["amendChip"] }
    private func amend(_ app: XCUIApplication) -> XCUIElement { app.descendants(matching: .any)["amend"] }
    private func track(_ board: XCUIElement, _ name: String) -> XCUIElement { board.descendants(matching: .any)["track.\(name)"] }

    private func openAmend(_ app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(chip(app).waitForExistence(timeout: 10))
        chip(app).tap()
        let board = amend(app)
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        return board
    }

    /// Press-to-position at the middle of a numeric track: stop 5.
    private func tapMiddle(_ board: XCUIElement, _ name: String) {
        let t = track(board, name)
        XCTAssertTrue(t.waitForExistence(timeout: 5))
        t.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testAmendChipShowsLockHour() {
        let app = launch(now: "2027-03-10T10:00:00")
        XCTAssertTrue(chip(app).waitForExistence(timeout: 10))
        XCTAssertEqual(chip(app).label, "until Wed 20:00")
    }

    func testAmendHiddenAtLockHourZero() {
        let app = launch(now: "2027-03-10T10:00:00", lockHour: 0)
        XCTAssertTrue(app.descendants(matching: .any)["track.Sleep"].waitForExistence(timeout: 10))
        XCTAssertFalse(chip(app).exists)
    }

    func testAmendWriteSurvivesRelaunch() {
        let store = UUID().uuidString
        var app = launch(now: "2027-03-10T10:00:00", store: store)
        var board = openAmend(app)
        XCTAssertTrue(board.descendants(matching: .any)["2027-03-09"].exists)
        tapMiddle(board, "Sleep")
        XCTAssertEqual(track(board, "Sleep").value as? String, "5")
        app.terminate()
        app = launch(now: "2027-03-10T10:00:00", store: store)
        board = openAmend(app)
        XCTAssertTrue(track(board, "Sleep").waitForExistence(timeout: 5))
        XCTAssertEqual(track(board, "Sleep").value as? String, "5")
    }

    func testDayTurnRelabelsWithoutReset() {
        let app = launch(now: "2027-03-10T23:59:57", lockHour: 23)
        let today = app.descendants(matching: .any)["track.Sleep"]
        XCTAssertTrue(today.waitForExistence(timeout: 10))
        today.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.descendants(matching: .any)["2027-03-10"].exists)
        // Past midnight: Today relabels to the new day and the value stays on its own date, now yesterday.
        XCTAssertTrue(app.descendants(matching: .any)["2027-03-11"].waitForExistence(timeout: 8))
        let board = openAmend(app)
        XCTAssertTrue(board.descendants(matching: .any)["2027-03-10"].exists)
        XCTAssertEqual(track(board, "Sleep").value as? String, "5")
    }

    func testYesterdayReadOnlyAfterClose() {
        let app = launch(now: "2027-03-10T19:59:40")
        let board = openAmend(app)
        let skipRest = board.buttons["Skip the rest of yesterday"]
        XCTAssertTrue(skipRest.waitForExistence(timeout: 5))
        // The close at 20:00 takes the day action away and the rows stop taking input.
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: skipRest)
        wait(for: [gone], timeout: 30)
        XCTAssertFalse(chip(app).exists)
        tapMiddle(board, "Sleep")
        XCTAssertEqual(track(board, "Sleep").value as? String, "not written yet")
    }

    func testAmendPadSaysSkipTheRestOfYesterday() {
        let app = launch(now: "2027-03-10T10:00:00")
        let board = openAmend(app)
        let skipRest = board.buttons["Skip the rest of yesterday"]
        XCTAssertTrue(skipRest.waitForExistence(timeout: 5))
        skipRest.tap()
        XCTAssertTrue(board.buttons["Sleep, skipped. Activate for choices"].waitForExistence(timeout: 5))
    }
}
