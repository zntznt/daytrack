import XCTest

final class ReminderUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// `notifications` nil uses the real centre; "fake" grants and "fakeDeny" refuses without a system alert.
    private func launch(_ seed: String = "threeTrackersEmpty", notifications: String? = "fake", settings: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestSeed", seed, "-uiTestNow", "2027-03-10T10:00:00", "-uiTestTZ", "Europe/London"]
            + (notifications.map { ["-uiTestNotifications", $0] } ?? []) + (settings ? ["-uiTestScreen", "settings"] : [])
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        return app
    }

    private func dayOne(_ app: XCUIApplication) -> XCUIElement { app.descendants(matching: .any)["dayOneWritten"] }

    private func skipRest(_ app: XCUIApplication) {
        let skip = app.buttons["Skip the rest of today"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
    }

    private func reminderToggle(_ app: XCUIApplication) -> XCUIElement {
        let toggle = app.switches["settings.reminder"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        return toggle
    }

    /// The switch sits at the trailing end of its row.
    private func turnOn(_ app: XCUIApplication) {
        let toggle = reminderToggle(app)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["settings.reminderScheduled"].waitForExistence(timeout: 5))
    }

    private func setTime(_ app: XCUIApplication, hour: String, minute: String) {
        let picker = app.datePickers["settings.reminderTime"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.buttons.firstMatch.exists ? picker.buttons.firstMatch.tap() : picker.tap()
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 5))
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: hour)
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: minute)
        // Close the wheel popover.
        app.navigationBars["Settings"].tap()
    }

    func testNoPermissionPromptAtLaunch() {
        // A written day before today: the day-one screen is up at launch, and still nothing is asked.
        let app = launch("fortyDays", notifications: nil)
        XCTAssertTrue(dayOne(app).waitForExistence(timeout: 5))
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    func testDayOneScreenOffersReminderAndNoReminder() {
        let app = launch()
        XCTAssertFalse(dayOne(app).exists)
        skipRest(app)
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
        skipRest(app)
        let remind = app.buttons["Remind me at 21:30"]
        XCTAssertTrue(remind.waitForExistence(timeout: 5))
        remind.tap()
        XCTAssertTrue(dayOne(app).waitForNonExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertEqual(reminderToggle(app).value as? String, "1")
        XCTAssertTrue(app.staticTexts["scheduled for 21:30; delivery can still move it"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nothing arrives tonight"].exists)
        XCTAssertTrue(app.staticTexts["Reminders are set 14 days ahead. If Daytrack is not opened for that long, they stop."].exists)
    }

    func testExplainerShowsChosenTime() {
        let app = launch(settings: true)
        XCTAssertEqual(reminderToggle(app).value as? String, "0")
        turnOn(app)
        XCTAssertFalse(app.staticTexts["Nothing arrives tonight"].exists)
        // Not the default: a hard-coded 21:30 or 21:00 fails here (design-review Medium 15).
        setTime(app, hour: "20", minute: "15")
        XCTAssertTrue(app.staticTexts["scheduled for 20:15; delivery can still move it"].waitForExistence(timeout: 5))
    }

    func testDeniedShowsSystemSettingsLine() {
        let app = launch(notifications: "fakeDeny", settings: true)
        reminderToggle(app).coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Notifications are off for Daytrack in system settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(reminderToggle(app).isEnabled)
    }
}
