import XCTest

final class ReminderUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// `notifications` nil uses the real centre; "fake" grants without a system alert.
    private func launch(_ seed: String = "threeTrackersEmpty", notifications: String? = "fake", settings: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestSeed", seed, "-uiTestNow", "2027-03-10T10:00:00", "-uiTestTZ", "Europe/London"]
            + (notifications.map { ["-uiTestNotifications", $0] } ?? []) + (settings ? ["-uiTestScreen", "settings"] : [])
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        return app
    }

    private func dayOne(_ app: XCUIApplication) -> XCUIElement { app.descendants(matching: .any)["dayOneWritten"] }

    private func reminderToggle(_ app: XCUIApplication) -> XCUIElement {
        if !app.navigationBars["Daily reminder"].exists { app.buttons["settings.reminderRow"].tap() }
        let toggle = app.switches["settings.reminder"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        return toggle
    }

    func testNoPermissionPromptAtLaunch() {
        // A written day before today: the day-one screen is up at launch, and still nothing is asked.
        let app = launch("fortyDays", notifications: nil)
        XCTAssertTrue(dayOne(app).waitForExistence(timeout: 5))
        XCTAssertFalse(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch.waitForExistence(timeout: 3))
    }

    func testDayOneScreenOffersReminderAndNoReminder() {
        let app = launch()
        XCTAssertFalse(dayOne(app).exists)
        app.buttons["Skip the rest of today"].tap()
        XCTAssertTrue(dayOne(app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["AFTER DAY ONE"].exists)
        XCTAssertTrue(app.staticTexts["Daily reminder"].exists)
        XCTAssertTrue(app.buttons["Remind me at 21:30"].exists)
        XCTAssertTrue(app.buttons["No reminder"].exists)
        // No "asks again" promise (design-review Medium 16).
        let texts = (app.staticTexts.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex).map { $0.label }.joined(separator: "\n").lowercased()
        for banned in ["again", "tomorrow"] { XCTAssertFalse(texts.contains(banned), banned) }
        app.buttons["No reminder"].tap()
        XCTAssertTrue(dayOne(app).waitForNonExistence(timeout: 5))
    }

    func testCompleteDaySaysNothingArrivesTonight() {
        let app = launch()
        app.buttons["Skip the rest of today"].tap()
        app.buttons["Remind me at 21:30"].tap()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertEqual(reminderToggle(app).value as? String, "1")
        XCTAssertTrue(app.staticTexts["scheduled for 21:30; delivery can still move it"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nothing arrives tonight"].exists)
        XCTAssertTrue(app.staticTexts["Reminders are set 14 days ahead. If Daytrack is not opened for that long, they stop."].exists)
    }

    func testExplainerShowsChosenTime() {
        let app = launch(settings: true)
        XCTAssertEqual(reminderToggle(app).value as? String, "0")
        // Tap the switch itself: a fixed offset into the row lands past its edge on narrower phones (17e).
        reminderToggle(app).switches.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["settings.reminderScheduled"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Nothing arrives tonight"].exists)
        // Not the default: a hard-coded 21:30 or 21:00 fails here (design-review Medium 15).
        app.datePickers["settings.reminderTime"].tap()
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 5))
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: "20")
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: "15")
        app.navigationBars["Daily reminder"].tap() // closes the wheels
        XCTAssertTrue(app.staticTexts["scheduled for 20:15; delivery can still move it"].waitForExistence(timeout: 5))
    }
}
