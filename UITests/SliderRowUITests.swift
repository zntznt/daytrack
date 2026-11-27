import XCTest

final class SliderRowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Sleep (numeric) blank, Anxiety (ordinal) "Mild", Meds taken (binary) skipped.
    private func launchRows() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestScreen", "sliderRows"]
        app.launch()
        XCTAssertTrue(track(app, "Anxiety").waitForExistence(timeout: 10))
        return app
    }

    private func track(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "track.\(name)").firstMatch
    }

    func testTapOnTrackSetsNearestStop() {
        let app = launchRows()
        let anxiety = track(app, "Anxiety")
        anxiety.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        XCTAssertEqual(anxiety.value as? String, "Moderate")
        XCTAssertTrue(app.buttons["Anxiety, Moderate. Activate for choices"].exists)
    }

    func testAccessibilityIncrementChangesWord() {
        let app = launchRows()
        let anxiety = track(app, "Anxiety")
        XCTAssertEqual(anxiety.value as? String, "Mild")
        // Blocked: iOS XCUIElement has no increment(); adjust(toNormalizedSliderPosition:) needs a slider with a numeric value.
        XCTFail("iOS XCUITest cannot send accessibilityIncrement to an adjustable element")
    }

    func testValueButtonLabelSaysNotWrittenYet() {
        let app = launchRows()
        XCTAssertTrue(app.buttons["Sleep, not written yet. Activate for choices"].exists)
        XCTAssertTrue(app.buttons["Meds taken, skipped. Activate for choices"].exists)
    }

    func testValueButtonIsSeparateFromTrack() {
        let app = launchRows()
        let button = app.buttons["Anxiety, Mild. Activate for choices"]
        let anxiety = track(app, "Anxiety")
        XCTAssertTrue(button.exists)
        XCTAssertNotEqual(anxiety.elementType, .button)
        XCTAssertFalse(button.frame.intersects(anxiety.frame))
        XCTAssertGreaterThanOrEqual(button.frame.width, 44)
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        // Tapping the value opens the pad; it never changes the value (decisions Q4).
        button.tap()
        XCTAssertEqual(anxiety.value as? String, "Mild")
    }
}
