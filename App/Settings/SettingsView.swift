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
                .listRowBackground(Tokens.surfaceRaised)
                Section("Day") {
                    // A pushed list, not `.pickerStyle(.navigationLink)`, so it takes the list look.
                    NavigationLink {
                        LockHourList(hours: hours, lockHour: lockHour, onPick: onPickLockHour)
                    } label: {
                        LabeledContent("Yesterday stays open until") {
                            Text(verbatim: hours.first { $0.hour == lockHour }?.label ?? "")
                        }
                    }
                    .accessibilityIdentifier("settings.lockHour")
                    reminderRows
                }
                .listRowBackground(Tokens.surfaceRaised)
                Section("Data") { dataRows }.listRowBackground(Tokens.surfaceRaised)
                Section {
                    LabeledContent("Version") { Text(verbatim: version) }
                        .accessibilityIdentifier("settings.version")
                }
                .listRowBackground(Tokens.surfaceRaised)
            }
            .daytrackList()
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

/// The hour list. It pops once the lock hour changes and stays while a lowering waits for its confirm.
private struct LockHourList: View {
    let hours: [(hour: Int, label: String)]
    let lockHour: Int
    let onPick: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(hours, id: \.hour) { item in
                Button { onPick(item.hour) } label: {
                    HStack {
                        Text(verbatim: item.label).foregroundStyle(Tokens.text)
                        Spacer()
                        if item.hour == lockHour {
                            Image(systemName: "checkmark").foregroundStyle(Tokens.accent).accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityAddTraits(item.hour == lockHour ? .isSelected : [])
            }
            .listRowBackground(Tokens.surfaceRaised)
        }
        .daytrackList()
        .navigationTitle("Yesterday stays open until")
        .onChange(of: lockHour) { dismiss() }
    }
}
