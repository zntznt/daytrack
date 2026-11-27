import SwiftUI

/// HANDOFF §4 colours. Warm hue band only: lightness carries the hierarchy, never grey.
enum Tokens {
    static let accent = Color(hex: 0xF6AC00)
    static let background = Color(hex: 0x120903)
    /// The lighter end of the ambient backdrop.
    static let surface = Color(hex: 0x1F1408)
    static let text = Color(hex: 0xFDCF6F)
    static let textSecondary = Color(hex: 0xB49A73)
    static let textFaint = Color(hex: 0xA08764)

    /// Layout spacing in points.
    enum Space {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    static let textHierarchy: [Color] = [text, textSecondary, textFaint]
    static let all: [(name: String, color: Color)] = [
        ("accent", accent), ("background", background), ("surface", surface),
        ("text", text), ("textSecondary", textSecondary), ("textFaint", textFaint),
    ]
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
