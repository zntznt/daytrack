import SwiftUI

/// After erasing: the exit, stated plainly (HANDOFF §3, screen 12 for flow only). Plain values and closures only.
struct ErasedView: View {
    let noOtherCopy: String
    let onStartAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "eraser").foregroundStyle(Tokens.textFaint).accessibilityHidden(true)
            Text("Nothing left").typography(.hero).foregroundStyle(Tokens.text).padding(.top, 22)
                .accessibilityIdentifier("erased.title")
            Text("Every day, note and tracker is gone from this phone.").typography(.body).foregroundStyle(Tokens.textSecondary)
                .padding(.top, 12)
            Text(verbatim: noOtherCopy).typography(.body).foregroundStyle(Tokens.textSecondary).padding(.top, 12)
                .accessibilityIdentifier("erased.noOtherCopy")
            Spacer(minLength: 28)
            Button(action: onStartAgain) {
                Text("Start again").frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("erased.startAgain")
            Text("Or close it and never open it again. That works too.").typography(.body).foregroundStyle(Tokens.textFaint)
                .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 15)
        }
        .padding(.horizontal, 22).padding(.top, 26).padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AmbientBackground())
        .tint(Tokens.accent)
        .controlSize(.large)
        .preferredColorScheme(.dark)
    }
}
