import DaytrackCore
import SwiftUI

/// Pick one to eight starters. A disabled Start states its reason underneath (HANDOFF §4).
struct StarterPickerView: View {
    let starters: [StarterTemplate]
    let picked: [StarterTemplate]
    let canStart: Bool
    let reason: String?
    let onToggle: (StarterTemplate) -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 11) {
                Text("Pick your first sliders").typography(.heading).foregroundStyle(Tokens.text)
                    .accessibilityAddTraits(.isHeader)
                Text("Three or four is plenty. The list is yours to change later. None of it is permanent.")
                    .typography(.body).foregroundStyle(Tokens.textSecondary)
            }
            .padding(.horizontal, 22).padding(.top, 26)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(starters, id: \.self) { starter in row(starter) }
                }
                .padding(.horizontal, 22).padding(.top, 20)
            }
            VStack(spacing: 11) {
                Button(action: onStart) {
                    Text("Start").frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(canStart ? Tokens.background : Tokens.textFaint)
                }
                .buttonStyle(.glassProminent)
                .disabled(!canStart)
                .accessibilityIdentifier("start")
                .accessibilityHint(reason ?? "")
                if let reason {
                    Text(reason).typography(.caption).foregroundStyle(Tokens.textSecondary)
                        .multilineTextAlignment(.center).accessibilityIdentifier("startReason")
                }
            }
            .padding(.horizontal, 22).padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AmbientBackground())
        .tint(Tokens.accent)
        .controlSize(.large)
        .preferredColorScheme(.dark)
    }

    private func row(_ starter: StarterTemplate) -> some View {
        let on = picked.contains(starter)
        return Button { onToggle(starter) } label: {
            HStack(spacing: 13) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(on ? Tokens.accent : Tokens.textFaint).font(.title3)
                Image(systemName: starter.symbol).foregroundStyle(Tokens.textSecondary).frame(width: 22)
                Text(starter.name).typography(.rowLabel).foregroundStyle(Tokens.text)
                Spacer()
            }
            .frame(minHeight: 56).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(starter.name)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}
