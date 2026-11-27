import SwiftUI
import UIKit

/// HANDOFF §4 type roles in system SF [O6]. Each size scales with Dynamic Type relative to a text style.
/// The web sizes below 15 are raised to readable iOS sizes; the hierarchy is kept.
enum Typography: CaseIterable {
    case hero, dayName, heading, subTitle, wordmark, rowLabel, body, numericValue, wordValue, monoLabel, caption

    var size: CGFloat {
        switch self {
        case .hero: 38
        case .dayName: 30
        case .heading: 27
        case .subTitle: 24
        case .wordmark: 21
        case .rowLabel, .wordValue: 17
        case .body: 15
        case .numericValue: 25
        case .monoLabel: 12
        case .caption: 13
        }
    }

    var relativeTo: UIFont.TextStyle {
        switch self {
        case .hero: .largeTitle
        case .dayName, .heading: .title1
        case .subTitle, .numericValue: .title2
        case .wordmark: .title3
        case .rowLabel, .wordValue: .body
        case .body: .subheadline
        case .monoLabel: .caption1
        case .caption: .footnote
        }
    }

    var weight: Font.Weight {
        switch self {
        case .hero, .dayName, .heading, .subTitle, .wordmark: .semibold
        case .rowLabel, .wordValue: .medium
        case .body, .numericValue, .monoLabel, .caption: .regular
        }
    }

    /// Tracking in em.
    var tracking: CGFloat {
        switch self {
        case .hero, .wordmark: -0.035
        case .dayName, .heading, .subTitle: -0.03
        case .numericValue: -0.02
        case .rowLabel, .wordValue: -0.01
        case .monoLabel: 0.1
        case .body, .caption: 0
        }
    }

    /// Numerals take monospaced digits [O6].
    var numerals: Bool { [.numericValue, .monoLabel, .caption].contains(self) }

    func pointSize(_ dynamicType: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicType))
        return UIFontMetrics(forTextStyle: relativeTo).scaledValue(for: size, compatibleWith: traits)
    }
}

private struct TypographyModifier: ViewModifier {
    let role: Typography
    @Environment(\.dynamicTypeSize) private var dynamicType

    func body(content: Content) -> some View {
        let size = role.pointSize(dynamicType)
        let font = Font.system(size: size, weight: role.weight)
        content
            .font(role.numerals ? font.monospacedDigit() : font)
            .tracking(role.tracking * size)
            .textCase(role == .monoLabel ? .uppercase : nil)
    }
}

extension View {
    func typography(_ role: Typography) -> some View { modifier(TypographyModifier(role: role)) }
}
