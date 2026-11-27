import SwiftUI

/// The day-one-written screen (decisions Q10, Q1 amendment 2). It offers the reminder once and promises nothing more.
struct DayOneWrittenView: View {
    /// "Remind me at 21:30", with the chosen time.
    let remindTitle: String
    let onRemind: () -> Void
    let onNoReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AFTER DAY ONE").typography(.monoLabel).foregroundStyle(Tokens.accent)
            Text("Daily reminder").typography(.wordmark).foregroundStyle(Tokens.text).accessibilityAddTraits(.isHeader)
            Text("The phone sets its own reminder. Nothing is sent anywhere, nothing arrives from anywhere.")
                .typography(.body).foregroundStyle(Tokens.textSecondary)
            Button(remindTitle, action: onRemind)
                .buttonStyle(.glassProminent).controlSize(.large).tint(Tokens.accent)
                .accessibilityIdentifier("dayOne.remind")
            Button("No reminder", action: onNoReminder)
                .foregroundStyle(Tokens.textSecondary)
                .accessibilityIdentifier("dayOne.noReminder")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.surface, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 22).padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("dayOneWritten")
    }
}
