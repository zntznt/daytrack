import DaytrackCore
import SwiftUI

/// Wires Settings to `SettingsService`. Lowering the lock hour below now waits for a confirm (Q1).
struct SettingsContainer: View {
    let state: AppState
    @Binding var path: [SettingsRoute]
    let onErased: () -> Void
    @State private var pendingHour: Int?

    var body: some View {
        SettingsView(path: $path,
                     hours: (0...23).map { ($0, Copy.settingsLockHour($0)) },
                     lockHour: state.store.record.settings.lockHour,
                     version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                     isConfirmingLower: pendingHour != nil,
                     onPickLockHour: { hour in
                         if (try? state.settings.setLockHour(hour)) == .needsConfirm { pendingHour = hour }
                     },
                     onConfirmLower: {
                         if let hour = pendingHour { try? state.settings.confirmLockHour(hour) }
                         pendingHour = nil
                     },
                     onCancelLower: { pendingHour = nil },
                     reminderRows: { ReminderSettingsContainer(state: state) },
                     dataRows: {
                         SaveCopyContainer(state: state)
                         EraseContainer(state: state, onErased: onErased)
                     },
                     destination: { route in
                         switch route {
                         case .trackers: TrackersContainer(state: state)
                         case .archived: ArchivedTrackersContainer(state: state)
                         }
                     })
    }
}
