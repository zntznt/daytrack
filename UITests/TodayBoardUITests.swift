import XCTest

final class TodayBoardUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ seed: String, store: String = "memory") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", store, "-uiTestSeed", seed]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        return app
    }

    private func track(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "track.\(name)").firstMatch
    }

    private func valueButton(_ app: XCUIApplication, _ name: String, _ said: String) -> XCUIElement {
        app.buttons["\(name), \(said). Activate for choices"]
    }

    private func dotStrip(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "dotStrip").firstMatch
    }

    /// Press-to-position at the middle of a numeric track: stop 5.
    private func tapMiddle(_ app: XCUIApplication, _ name: String) {
        let t = track(app, name)
        XCTAssertTrue(t.waitForExistence(timeout: 5))
        t.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(t.value as? String, "5")
    }

    func testOneRowPerActiveTrackerInRosterOrder() {
        let app = launch("threeTrackersEmpty")
        XCTAssertTrue(track(app, "Focus").waitForExistence(timeout: 5))
        let tracks = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'track.'")).allElementsBoundByIndex
        let order = tracks.sorted { $0.frame.minY < $1.frame.minY }.map { $0.identifier }
        XCTAssertEqual(order, ["track.Sleep", "track.Energy", "track.Focus"])
    }

    func testDayOneHasNoTapToSkipHint() {
        let app = launch("threeTrackersEmpty")
        XCTAssertTrue(app.staticTexts["Drag any track to set it."].waitForExistence(timeout: 5))
        let texts = app.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: "\n").lowercased()
        for banned in ["tap the number", "to skip", "late", "behind"] {
            XCTAssertFalse(texts.contains(banned), banned)
        }
        // The value button is the skip affordance on every row (design-review Medium 12).
        XCTAssertTrue(valueButton(app, "Sleep", "not written yet").exists)
    }

    func testTapWritesAndSurvivesRelaunch() {
        let store = UUID().uuidString
        var app = launch("threeTrackersEmpty", store: store)
        tapMiddle(app, "Sleep")
        XCTAssertTrue(valueButton(app, "Sleep", "5").exists)
        app.terminate()
        app = launch("threeTrackersEmpty", store: store)
        XCTAssertTrue(valueButton(app, "Sleep", "5").waitForExistence(timeout: 5))
        XCTAssertEqual(track(app, "Sleep").value as? String, "5")
    }

    func testDotStripCountsSkippedSeparately() {
        let app = launch("threeTrackersEmpty")
        XCTAssertEqual(dotStrip(app).label, "0 written, 0 skipped, 3 still blank")
        tapMiddle(app, "Sleep")
        valueButton(app, "Energy", "not written yet").tap()
        XCTAssertTrue(app.buttons["Skip Energy"].waitForExistence(timeout: 5))
        app.buttons["Skip Energy"].tap()
        XCTAssertTrue(valueButton(app, "Energy", "skipped").waitForExistence(timeout: 5))
        XCTAssertEqual(dotStrip(app).label, "1 written, 1 skipped, 1 still blank")
    }

    func testSkipRestFillsOnlyBlanks() {
        let app = launch("threeTrackersEmpty")
        tapMiddle(app, "Sleep")
        app.buttons["Skip the rest of today"].tap()
        XCTAssertTrue(valueButton(app, "Energy", "skipped").waitForExistence(timeout: 5))
        XCTAssertTrue(valueButton(app, "Focus", "skipped").exists)
        XCTAssertTrue(valueButton(app, "Sleep", "5").exists)
        XCTAssertEqual(dotStrip(app).label, "1 written, 2 skipped, 0 still blank")
        XCTAssertFalse(app.buttons["Skip the rest of today"].exists)
    }

    func testBoardEmptyWhenAllArchivedSuppressesDotStripAndStatesNoNudge() {
        let app = launch("allArchived")
        XCTAssertTrue(app.staticTexts["Nothing on the board"].waitForExistence(timeout: 5))
        XCTAssertFalse(dotStrip(app).exists)
        XCTAssertFalse(track(app, "Sleep").exists)
        XCTAssertTrue(app.staticTexts["There is no nudge tonight either. A reminder for a board with nothing on it would be asking about nothing."].exists)
        let bring = app.buttons["Bring one back"]
        XCTAssertTrue(bring.exists)
        bring.tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
    }

    func testEightRowsHittableWithoutScrolling() {
        let app = launch("eightTrackers")
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        for name in ["Sleep", "Energy", "Focus", "Mood", "Movement", "Work", "Anxiety", "Meds taken"] {
            let t = track(app, name)
            XCTAssertTrue(t.waitForExistence(timeout: 5), name)
            print("row \(name) track \(t.frame) tabBarTop \(tabBarTop)")
            XCTAssertTrue(t.isHittable, name)
            // Above the tab bar, not merely on screen behind it.
            XCTAssertLessThanOrEqual(t.frame.maxY, tabBarTop, name)
            XCTAssertGreaterThanOrEqual(t.frame.height.rounded(), 44, name)
            let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(name), ")).firstMatch
            XCTAssertTrue(button.isHittable, name)
        }
    }
}
