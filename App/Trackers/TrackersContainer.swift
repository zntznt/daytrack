import DaytrackCore
import SwiftUI

/// Settings › Trackers wired to `TrackerManager`: the active roster, add from the catalog, archive.
struct TrackersContainer: View {
    let state: AppState

    var body: some View {
        let trackers = state.store.record.trackers
        TrackersView(active: trackers.filter { !$0.isArchived },
                     // A catalog entry already on the roster, active or archived, is not offered twice.
                     catalog: StarterCatalog.all.filter { template in !trackers.contains { $0.name == template.name } },
                     fullReason: fullReason(trackers),
                     onAdd: { try? state.trackers.createFromCatalog($0) },
                     onArchive: { try? state.trackers.archive($0.id) })
    }
}

/// Settings › Trackers › Archived wired to `TrackerManager`: bring one back, refused at eight.
struct ArchivedTrackersContainer: View {
    let state: AppState

    var body: some View {
        let trackers = state.store.record.trackers
        ArchivedTrackersView(archived: trackers.filter(\.isArchived), fullReason: fullReason(trackers),
                             onBringBack: { try? state.trackers.bringBack($0.id) })
    }
}

/// The line a disabled add or bring-back states and announces; nil while the board has room (Q11a).
private func fullReason(_ trackers: [Tracker]) -> String? {
    switch Roster.canActivate(alongside: trackers) {
    case .allowed: nil
    case .refused(let reason): reason
    }
}
