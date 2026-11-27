import SwiftUI

/// Settings: Trackers, Day, Data, then the version (HANDOFF §3, Q7a). Plain values and closures only.
struct SettingsView: View {
    /// Each hour 0–23 with its derived label (`Copy.settingsLockHour`).
    let hours: [(hour: Int, label: String)]
    let lockHour: Int
    let version: String
    let isConfirmingLower: Bool
    let onPickLockHour: (Int) -> Void
    let onConfirmLower: () -> Void
    let onCancelLower: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Placeholder until M3.15.
                    NavigationLink("Trackers") { Text("Trackers") }
                        .accessibilityIdentifier("settings.trackers")
                }
                Section("Day") {
                    Picker("Yesterday stays open until", selection: Binding(get: { lockHour }, set: onPickLockHour)) {
                        ForEach(hours, id: \.hour) { Text(verbatim: $0.label).tag($0.hour) }
                    }
                    .pickerStyle(.navigationLink)
                    .accessibilityIdentifier("settings.lockHour")
                }
                Section("Data") {} // M3.11 fills it.
                Section {
                    LabeledContent("Version") { Text(verbatim: version) }
                        .accessibilityIdentifier("settings.version")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AmbientBackground())
            .navigationTitle("Settings")
        }
        // On the stack, not the list: the hour list is still pushed when the confirm is asked.
        .alert("Close yesterday now?", isPresented: Binding(get: { isConfirmingLower }, set: { if !$0 { onCancelLower() } })) {
            Button("Close yesterday", role: .destructive, action: onConfirmLower)
            Button("Cancel", role: .cancel, action: onCancelLower)
        }
    }
}
