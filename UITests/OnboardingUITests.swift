import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory"] + arguments
        app.launch()
        return app
    }

    /// Launches into the starter picker.
    private func picker() -> XCUIApplication {
        let app = launch()
        let pick = app.buttons["Pick your first sliders"]
        XCTAssertTrue(pick.waitForExistence(timeout: 10))
        pick.tap()
        XCTAssertTrue(app.buttons["start"].waitForExistence(timeout: 5))
        return app
    }

    func testPickTwoLandsOnTodayTab() {
        let app = picker()
        app.buttons["Sleep"].tap()
        app.buttons["Mood"].tap()
        app.buttons["start"].tap()
        let today = app.tabBars.buttons["Today"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(today.isSelected)
    }

    func testOnboardingStatesCopyPromiseAndNoCloud() {
        let app = launch()
        XCTAssertTrue(app.buttons["Pick your first sliders"].waitForExistence(timeout: 10))
        let texts = app.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: "\n")
        XCTAssertTrue(texts.contains("Keep a copy whenever"), texts)
        XCTAssertTrue(texts.contains("One tap saves a file you keep. Daytrack never sees where it goes."), texts)
        for banned in ["cloud", "google drive", "backup"] {
            XCTAssertFalse(texts.lowercased().contains(banned), banned)
        }
        XCTAssertFalse(app.buttons["I already have Daytrack days"].exists)
    }

    func testNinthPickRefusedWithReason() {
        let app = picker()
        let names = ["Sleep", "Energy", "Focus", "Mood", "Movement", "Work", "Anxiety", "Meds taken", "Eating"]
        for name in names {
            let row = app.buttons[name]
            if !row.isHittable { app.swipeUp() }
            row.tap()
        }
        XCTAssertFalse(app.buttons["Eating"].isSelected)
        XCTAssertTrue(app.buttons["Meds taken"].isSelected)
        XCTAssertEqual(app.staticTexts["startReason"].label, "Eight fit on one board. Archive one to make room.")
        XCTAssertTrue(app.buttons["start"].isEnabled)
    }

    func testNoPickStartDisabledWithReason() {
        let app = picker()
        XCTAssertFalse(app.buttons["start"].isEnabled)
        XCTAssertEqual(app.staticTexts["startReason"].label, "Pick at least one")
        app.buttons["Sleep"].tap()
        XCTAssertTrue(app.buttons["start"].isEnabled)
        XCTAssertFalse(app.staticTexts["startReason"].exists)
    }

    func testOnboardingNotShownWhenTrackersExist() {
        let app = launch(["-uiTestSeed", "threeTrackersEmpty"])
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Pick your first sliders"].exists)
    }
}
