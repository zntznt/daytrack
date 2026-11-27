import SwiftUI

/// How a glass surface draws, given the legibility settings.
enum GlassStyle: String {
    case glass, solidWarm, solidWarmBordered

    /// Increase Contrast wins over Reduce Transparency. In DEBUG, `-uiTestLegibility` forces one setting on,
    /// because the SwiftUI environment values are read-only.
    static func resolve(reduceTransparency: Bool, increaseContrast: Bool) -> GlassStyle {
        var (reduce, contrast) = (reduceTransparency, increaseContrast)
        #if DEBUG
        switch LaunchOverrides.legibility {
        case .reduceTransparency?: reduce = true
        case .increaseContrast?: contrast = true
        case nil: break
        }
        #endif
        return contrast ? .solidWarmBordered : reduce ? .solidWarm : .glass
    }
}

private struct GlassSurface: ViewModifier {
    let radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        switch GlassStyle.resolve(reduceTransparency: reduceTransparency, increaseContrast: contrast == .increased) {
        case .glass: content.glassEffect(.regular, in: shape)
        case .solidWarm: content.background(Palette.surface, in: shape)
        case .solidWarmBordered: content.background(Palette.surface, in: shape).overlay(shape.strokeBorder(Palette.dim, lineWidth: 1))
        }
    }
}

extension View {
    /// Glass in a rounded rectangle; `radius` is a `Radius` token.
    func glassSurface(radius: CGFloat) -> some View { modifier(GlassSurface(radius: radius)) }
}

/// Groups glass surfaces so they blend and morph together.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder let content: Content

    var body: some View { GlassEffectContainer(spacing: spacing) { content } }
}

/// The warm ambient background the glass refracts. Hue band 60–100, no grey.
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A1A08), Palette.background], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Palette.accent.opacity(0.18), .clear], center: .topLeading, startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Palette.ok.opacity(0.1), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
