import SwiftUI

/// No account wall. No cloud of any kind is offered or named (design-review High 5, Q2).
struct WelcomeView: View {
    let onPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daytrack").typography(.wordmark).foregroundStyle(Tokens.text)
            Text("No account").typography(.monoLabel).foregroundStyle(Tokens.accent).padding(.top, 34)
            Text("Everything stays on this phone.").typography(.hero).foregroundStyle(Tokens.text).padding(.top, 20)
            Text("Sliders in, numbers out. No step in between.").typography(.body).foregroundStyle(Tokens.textSecondary).padding(.top, 16)
            VStack(alignment: .leading, spacing: 22) {
                promise("lock.fill", "On-device storage", "No sign-up, no email, no password.")
                promise("square.and.arrow.down.fill", "Keep a copy whenever", "One tap saves a file you keep. Daytrack never sees where it goes.")
                // [O5] Markdown and Health export are cut from v1.
                promise("square.and.arrow.up.fill", "Leave whenever", "CSV, JSON, PDF.")
            }
            .padding(.top, 46)
            Spacer(minLength: 28)
            Button(action: onPick) {
                Text("Pick your first sliders").frame(maxWidth: .infinity, minHeight: 36).foregroundStyle(Tokens.background)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, 22).padding(.top, 26).padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AmbientBackground())
        .tint(Tokens.accent)
        .controlSize(.large)
        .preferredColorScheme(.dark)
    }

    private func promise(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 15) {
            Image(systemName: symbol).foregroundStyle(Tokens.accent).frame(width: 22).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).typography(.rowLabel).foregroundStyle(Tokens.text)
                Text(detail).typography(.body).foregroundStyle(Tokens.textFaint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
