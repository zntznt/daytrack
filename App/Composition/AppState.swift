import DaytrackCore
import Foundation
import Observation

/// The one observable app state. `route` follows every saved record, so onboarding, erase and restore switch it.
@MainActor @Observable
final class AppState {
    enum Route: Hashable { case onboarding, tabs, unreadable(keptAt: URL) }

    @ObservationIgnored let store: ObservedRecordStore
    @ObservationIgnored let recorder: Recorder
    @ObservationIgnored let settings: SettingsService
    @ObservationIgnored let trackers: TrackerManager
    @ObservationIgnored let env: AppEnvironment
    private var unreadableAt: URL?

    init(_ env: AppEnvironment) {
        store = ObservedRecordStore(env.records)
        let loaded: LoadResult
        do { loaded = try store.load() } catch {
            // Saving over a record that could not even be opened would lose it.
            fatalError("record store could not be opened: \(error)")
        }
        recorder = Recorder(record: store.record, store: store, clock: env.clock, widget: env.widget,
                            reminders: env.reminders, tz: env.timeZone)
        settings = SettingsService(recorder: recorder, deviceState: env.deviceState)
        trackers = TrackerManager(recorder: recorder, tz: env.timeZone)
        self.env = env
        if case .unreadable(let keptAt) = loaded { unreadableAt = keptAt }
    }

    var route: Route {
        if let unreadableAt { return .unreadable(keptAt: unreadableAt) }
        return store.record.trackers.isEmpty ? .onboarding : .tabs
    }

    /// The unreadable file is already moved aside, so the store is empty.
    func continueFromUnreadable() { unreadableAt = nil }
}

/// Remembers the record last loaded or saved, observably.
/// shortcut: unsynchronised; every save runs on the main actor today. Add a lock if a background writer lands.
@Observable
final class ObservedRecordStore: RecordStore, @unchecked Sendable {
    @ObservationIgnored private let base: RecordStore
    private(set) var record = Record()

    init(_ base: RecordStore) { self.base = base }

    func load() throws -> LoadResult {
        let result = try base.load()
        if case .loaded(let loaded) = result { record = loaded }
        return result
    }

    func save(_ record: Record) throws { try base.save(record); self.record = record }
}
