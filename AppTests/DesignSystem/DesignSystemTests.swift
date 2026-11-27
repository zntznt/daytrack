import SwiftUI
import Testing
import UIKit
@testable import Daytrack

@Suite struct DesignSystemTests {
    /// Warm means red over green over blue with real saturation; grey would have r ≈ g ≈ b.
    @Test func paletteTextIsWarmNotGrey() {
        for color in Tokens.textHierarchy {
            var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
            #expect(UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a))
            #expect(r > g && g > b)
            #expect((r - b) / r > 0.25)
        }
    }

    @Test func typographyScalesWithDynamicType() {
        for role in Typography.allCases {
            #expect(abs(role.pointSize(.large) - role.size) < 0.01)
            #expect(role.pointSize(.accessibility5) > role.pointSize(.large))
            #expect(role.pointSize(.xSmall) < role.pointSize(.large))
        }
    }
}
