import SwiftUI

/// Settings › Data: "Erase everything", then the confirm in place with the real counts (HANDOFF §3). Plain values and closures only.
struct EraseView: View {
    /// The counts line while confirming; nil otherwise.
    let confirm: String?
    let noOtherCopy: String
    let onAsk: () -> Void
    let onKeep: () -> Void
    let onErase: () -> Void

    var body: some View {
        if let confirm {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: confirm).accessibilityIdentifier("erase.confirm")
                Text(verbatim: noOtherCopy).foregroundStyle(.secondary).accessibilityIdentifier("erase.noOtherCopy")
            }
            Button("Keep it", action: onKeep).accessibilityIdentifier("erase.keep")
            Button("Erase it all", role: .destructive, action: onErase).accessibilityIdentifier("erase.eraseAll")
        } else {
            Button("Erase everything", role: .destructive, action: onAsk).accessibilityIdentifier("settings.erase")
        }
    }
}
