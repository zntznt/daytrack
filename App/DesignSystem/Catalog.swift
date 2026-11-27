#if DEBUG
import SwiftUI

/// Every design-system atom over the ambient background (`-uiTestScreen catalog`).
struct CatalogView: View {
    @State private var picked: Set<String> = ["Mood"]
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private let chips = ["Mood", "Sleep", "Energy"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Typography.allCases, id: \.self) { role in
                        Text(verbatim: "\(role) 0123").typography(role).foregroundStyle(Palette.text)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Primary text").foregroundStyle(Palette.text)
                    Text(verbatim: "Secondary text").foregroundStyle(Palette.dim)
                    Text(verbatim: "Caption text").foregroundStyle(Palette.faint)
                    Text(verbatim: "Accent").foregroundStyle(Palette.accent)
                    Text(verbatim: "Confirmed").foregroundStyle(Palette.ok)
                }
                .typography(.rowLabel)
                Text(verbatim: "Glass style: \(GlassStyle.resolve(reduceTransparency: reduceTransparency, increaseContrast: contrast == .increased).rawValue)")
                    .typography(.body)
                    .foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassSurface(radius: Radius.card)
                    .accessibilityIdentifier("glassStyle")
                GlassGroup {
                    ViewThatFits {
                        HStack(spacing: 8) { chipViews }
                        VStack(alignment: .leading, spacing: 8) { chipViews }
                    }
                }
                PrimaryButton(title: "Start", action: {})
                PrimaryButton(title: "Continue", disabledReason: "Pick at least one tracker", action: {})
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
        }
        .background { AmbientBackground() }
    }

    private var chipViews: some View {
        ForEach(chips, id: \.self) { name in
            Chip(title: name, isSelected: picked.contains(name)) {
                if picked.contains(name) { picked.remove(name) } else { picked.insert(name) }
            }
        }
    }
}
#endif
