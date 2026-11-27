import DaytrackCore
import SwiftUI

/// The active trackers in board order. Swipe to archive; "+" adds from the catalog (HANDOFF §3 Manage, Q11a, Q11b).
struct TrackersView: View {
    let active: [Tracker]
    let catalog: [StarterTemplate]
    /// Why nothing can be added; nil while the board has room.
    let fullReason: String?
    let onAdd: (StarterTemplate) -> Void
    let onArchive: (Tracker) -> Void

    var body: some View {
        List {
            Section {
                ForEach(active) { tracker in
                    Label(tracker.name, systemImage: tracker.symbol)
                        .foregroundStyle(Tokens.text)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("trackers.row.\(tracker.name)")
                        .swipeActions { Button("Archive") { onArchive(tracker) }.tint(Tokens.accent) }
                }
            } footer: {
                if let fullReason { Text(fullReason).foregroundStyle(Tokens.textSecondary) }
            }
            Section {
                NavigationLink("Archived", value: SettingsRoute.archived)
                    .accessibilityIdentifier("trackers.archived")
            }
        }
        .daytrackList()
        .navigationTitle("Trackers")
        .toolbar {
            Menu {
                Section("Start from a common one") {
                    ForEach(catalog, id: \.name) { template in
                        Button(template.name, systemImage: template.symbol) { onAdd(template) }
                    }
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
            .disabled(fullReason != nil || catalog.isEmpty)
            .accessibilityHint(fullReason ?? "")
            .accessibilityIdentifier("trackers.add")
        }
    }
}

/// Archived trackers: off the board, every day kept. "Put back on Today" is refused at eight with the reason (Q11a).
struct ArchivedTrackersView: View {
    let archived: [Tracker]
    let fullReason: String?
    let onBringBack: (Tracker) -> Void

    var body: some View {
        List {
            Section {
                Text("Off the board, still in the record. Every day an archived tracker wrote stays in your history, its charts and every export. It simply stopped asking.")
                    .foregroundStyle(Tokens.textSecondary)
            }
            Section {
                ForEach(archived) { tracker in
                    HStack {
                        Label(tracker.name, systemImage: tracker.symbol).foregroundStyle(Tokens.text)
                        Spacer()
                        Button("Put back on Today") { onBringBack(tracker) }
                            .buttonStyle(.glass)
                            .tint(Tokens.accent)
                            .disabled(fullReason != nil)
                            .accessibilityHint(fullReason ?? "")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("archived.row.\(tracker.name)")
                }
            } footer: {
                if let fullReason { Text(fullReason).foregroundStyle(Tokens.textSecondary) }
            }
        }
        .daytrackList()
        .navigationTitle("Archived")
    }
}
