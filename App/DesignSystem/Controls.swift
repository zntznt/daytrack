import SwiftUI

/// The one accent CTA on a screen. Height 50, radius 14. When disabled it states why underneath.
struct PrimaryButton: View {
    let title: String
    var disabledReason: String?
    let action: () -> Void

    var body: some View {
        let enabled = disabledReason == nil
        VStack(spacing: 8) {
            Button(action: action) {
                Text(title)
                    .typography(.rowLabel)
                    .foregroundStyle(enabled ? Palette.background : Palette.faint)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(enabled ? Palette.accent : Palette.surface2,
                                in: RoundedRectangle(cornerRadius: Radius.cta, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            if let disabledReason {
                Text(disabledReason).typography(.caption).foregroundStyle(Palette.dim)
            }
        }
    }
}

/// A glass pill, at least 44pt tall.
struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(.wordValue)
                .foregroundStyle(isSelected ? Palette.accent : Palette.text)
                .padding(.horizontal, 16)
                .frame(minWidth: 44, minHeight: 44)
                .glassSurface(radius: Radius.pill)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
