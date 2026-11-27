import SwiftUI

/// "until Wed 20:00": opens yesterday's board. A system glass button in the header, a slot no strip displaces (design-review Medium 10).
struct AmendChipView: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(title, action: onTap)
            .buttonStyle(.glass)
            .controlSize(.small)
            .tint(Tokens.accent)
            .accessibilityIdentifier("amendChip")
    }
}
