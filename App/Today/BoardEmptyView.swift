import SwiftUI

/// HANDOFF §9 boardEmpty: every tracker archived. States the fact, why it is fine, and the one action that changes it.
struct BoardEmptyView: View {
    let onBringBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nothing on the board").typography(.wordmark).foregroundStyle(Tokens.text)
                Text("Every tracker is archived. The record is untouched — archiving takes something off the board, not out of the past.")
                    .typography(.body).foregroundStyle(Tokens.textSecondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Tokens.textFaint, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            Button("Bring one back", action: onBringBack)
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(Tokens.accent)
            Text("There is no nudge tonight either. A reminder for a board with nothing on it would be asking about nothing.")
                .typography(.caption).foregroundStyle(Tokens.textFaint)
        }
    }
}
