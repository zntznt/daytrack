import SwiftUI

/// One day's note (HANDOFF §3 Note). No save button: the container saves as you type.
struct NoteView: View {
    let title: String
    @Binding var text: String
    /// False once the day has closed: the note shows as written.
    let isEditable: Bool
    let footer: String
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if isEditable {
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .typography(.body).foregroundStyle(Tokens.text)
                        .accessibilityIdentifier("noteEditor")
                } else {
                    ScrollView {
                        Text(verbatim: text)
                            .typography(.body).foregroundStyle(Tokens.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("noteText")
                    }
                }
                Text(verbatim: footer)
                    .typography(.caption).foregroundStyle(Tokens.textSecondary)
                    .accessibilityIdentifier("noteFooter")
            }
            .padding(.horizontal, 22)
            .background(AmbientBackground())
            .navigationTitle(Text(verbatim: title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: onDone) } }
        }
        .preferredColorScheme(.dark)
    }
}
