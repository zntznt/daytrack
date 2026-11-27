import SwiftUI

/// Settings: Trackers, Day (with the reminder), Data, then the version (HANDOFF §3, Q7a). Plain values and closures only.
struct SettingsView<ReminderRows: View, DataRows: View, Destination: View>: View {
    @Binding var path: [SettingsRoute]
    /// Each hour 0–23 with its derived label (`Copy.settingsLockHour`).
    let hours: [(hour: Int, label: String)]
    let lockHour: Int
    let version: String
    let isConfirmingLower: Bool
    let onPickLockHour: (Int) -> Void
    let onConfirmLower: () -> Void
    let onCancelLower: () -> Void
    @ViewBuilder let reminderRows: ReminderRows
    @ViewBuilder let dataRows: DataRows
    @ViewBuilder let destination: (SettingsRoute) -> Destination

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink("Trackers", value: SettingsRoute.trackers)
                        .accessibilityIdentifier("settings.trackers")
                }
                Section("Day") {
                    Picker("Yesterday stays open until", selection: Binding(get: { lockHour }, set: onPickLockHour)) {
                        ForEach(hours, id: \.hour) { Text(verbatim: $0.label).tag($0.hour) }
                    }
                    .pickerStyle(.navigationLink)
                    .accessibilityIdentifier("settings.lockHour")
                    reminderRows
                }
                Section("Data") { dataRows }
                Section {
                    LabeledContent("Version") { Text(verbatim: version) }
                        .accessibilityIdentifier("settings.version")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AmbientBackground())
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self, destination: destination)
        }
        // On the stack, not the list: the hour list is still pushed when the confirm is asked.
        .alert("Close yesterday now?", isPresented: Binding(get: { isConfirmingLower }, set: { if !$0 { onCancelLower() } })) {
            Button("Close yesterday", role: .destructive, action: onConfirmLower)
            Button("Cancel", role: .cancel, action: onCancelLower)
        }
    }
}
