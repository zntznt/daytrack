import XCTest

@MainActor
final class DesignSystemUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Opens the catalog and waits for its glass-style readout.
    private func launchCatalog(_ arguments: [String] = []) -> (XCUIApplication, XCUIElement) {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestScreen", "catalog"] + arguments
        app.launch()
        let style = app.staticTexts["glassStyle"]
        XCTAssertTrue(style.waitForExistence(timeout: 10))
        return (app, style)
    }

    func testCatalogRendersUnderForcedReduceTransparency() {
        let (app, style) = launchCatalog(["-uiTestLegibility", "reduceTransparency"])
        XCTAssertEqual(style.label, "Glass style: solidWarm")
        XCTAssertTrue(app.buttons["Mood"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)
    }

    func testAllCatalogControlsAtLeast44pt() {
        let (app, _) = launchCatalog()
        let buttons = app.buttons.allElementsBoundByIndex
        XCTAssertFalse(buttons.isEmpty)
        for button in buttons {
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, button.label)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, button.label)
        }
    }

    func testCatalogPassesAccessibilityAudit() throws {
        let (app, _) = launchCatalog()
        // Never ignores an issue; prints each so the log names the element.
        try app.performAccessibilityAudit { issue in
            print("audit issue: \(issue.compactDescription) on '\(issue.element?.label ?? "?")'")
            return false
        }
    }
}
