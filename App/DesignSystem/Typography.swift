import SwiftUI

/// HANDOFF §4 type roles in system SF [O6]. Sizes scale with Dynamic Type; numerals take monospaced digits.
enum Typography: CaseIterable {
    case hero, boardDay, heading, subTitle, wordmark, rowLabel, body, numeric, wordValue, monoLabel, caption

    var size: CGFloat {
        switch self {
        case .hero: 38
        case .boardDay: 30
        case .heading: 27
        case .subTitle: 24
        case .wordmark: 21
        case .rowLabel: 15
        case .body: 12.5
        case .numeric: 25
        case .wordValue: 14.5
        case .monoLabel: 10
        case .caption: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .hero, .boardDay, .heading, .subTitle, .wordmark: .semibold
        case .rowLabel, .wordValue: .medium
        case .body, .numeric, .monoLabel, .caption: .regular
        }
    }

    /// Tracking in em.
    var tracking: CGFloat {
        switch self {
        case .hero, .wordmark: -0.035
        case .boardDay, .heading, .subTitle: -0.03
        case .numeric: -0.02
        case .rowLabel, .wordValue: -0.01
        case .monoLabel: 0.1
        case .body, .caption: 0
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .hero: .largeTitle
        case .boardDay, .heading: .title
        case .subTitle, .wordmark: .title2
        case .numeric: .title3
        case .rowLabel, .wordValue: .body
        case .body: .callout
        case .monoLabel, .caption: .caption
        }
    }

    var numerals: Bool { self == .numeric || self == .monoLabel || self == .caption }

    /// Extra line spacing as a fraction of the size (body 1.6, caption 1.5).
    var leading: CGFloat { self == .body ? 0.6 : self == .caption ? 0.5 : 0 }
}

private struct TypographyModifier: ViewModifier {
    let role: Typography
    @ScaledMetric private var size: CGFloat

    init(_ role: Typography) {
        self.role = role
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.textStyle)
    }

    func body(content: Content) -> some View {
        let font = Font.system(size: size, weight: role.weight)
        content
            .font(role.numerals ? font.monospacedDigit() : font)
            .tracking(role.tracking * size)
            .lineSpacing(role.leading * size)
            .textCase(role == .monoLabel ? .uppercase : nil)
    }
}

extension View {
    func typography(_ role: Typography) -> some View { modifier(TypographyModifier(role)) }
}
