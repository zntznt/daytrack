import XCTest

final class DesignSystemUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchCatalog() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "memory", "-uiTestScreen", "catalog"]
        app.launch()
        XCTAssertTrue(app.buttons["Glass"].waitForExistence(timeout: 10))
        return app
    }

    func testAllCatalogControlsAtLeast44pt() {
        let buttons = launchCatalog().buttons.allElementsBoundByIndex
        XCTAssertEqual(buttons.count, 5)
        for button in buttons {
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, button.label)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, button.label)
        }
    }

    func testCatalogPassesAccessibilityAudit() throws {
        try launchCatalog().performAccessibilityAudit { issue in
            // The system draws the .glass button's tinted label over live glass; the system owns that contrast (decisions: Visual, revised).
            issue.auditType == .contrast && issue.element?.elementType == .button && issue.element?.label == "Glass"
        }
    }
}
