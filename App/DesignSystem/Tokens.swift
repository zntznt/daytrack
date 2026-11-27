import SwiftUI

/// HANDOFF §4 colours, all in hue band 60–100. There is no grey: lightness carries the hierarchy.
enum Palette {
    static let background = Color(hex: 0x120903)
    static let surface = Color(hex: 0x1F1408)
    static let surface2 = Color(hex: 0x302110)
    static let line = Color(hex: 0x42301B)
    /// Primary text, the lightest token.
    static let text = Color(hex: 0xFDCF6F)
    /// Secondary text, icons at rest.
    static let dim = Color(hex: 0xB49A73)
    /// Captions and labels.
    static let faint = Color(hex: 0xA08764)
    /// Fill, handles, the CTA. One per screen.
    static let accent = Color(hex: 0xF6AC00)
    /// Confirmed state, and a chart's second series.
    static let ok = Color(hex: 0xD5BF2C)
}

/// HANDOFF §4 corner radii, in points.
enum Radius {
    static let pill: CGFloat = 999
    static let cta: CGFloat = 14
    static let card: CGFloat = 13
    static let tile: CGFloat = 12
    static let nested: CGFloat = 11
    static let key: CGFloat = 10
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
