import DaytrackCore
import Foundation
import Observation

/// Save a full copy (Q2): write the file to `directory` first, hand it to the exporter, delete it when the exporter closes.
/// Only a save records `lastFullCopyAt`; a cancel changes nothing and says so (HANDOFF §8).
@MainActor @Observable
final class SaveCopyModel {
    @ObservationIgnored private let settings: SettingsService
    @ObservationIgnored private let clock: Clock
    @ObservationIgnored private let timeZone: TimeZone
    @ObservationIgnored private let directory: URL
    private(set) var lastFullCopyAt: Date?
    /// The written file while the exporter is open.
    private(set) var pending: URL?
    /// Shown under the button until the next save attempt.
    private(set) var notSaved = false

    init(settings: SettingsService, deviceState: DeviceStateStore, clock: Clock, timeZone: TimeZone, directory: URL) {
        (self.settings, self.clock, self.timeZone, self.directory) = (settings, clock, timeZone, directory)
        lastFullCopyAt = try? deviceState.load().lastFullCopyAt
    }

    /// Writes `daytrack-YYYY-MM-DD.json`; the exporter is shown only once `pending` is set.
    func prepare(_ record: Record) {
        notSaved = false
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(CopyFileCodec.fileName(on: clock.now, timeZone: timeZone))
            try CopyFileCodec.encode(record).write(to: url, options: .atomic)
            pending = url
        } catch {
            notSaved = true
        }
    }

    /// The exporter closed. A failed save is reported like a cancel: nothing changed.
    func finish(saved: Bool) {
        if let pending { try? FileManager.default.removeItem(at: pending) }
        pending = nil
        if saved, (try? settings.recordFullCopySaved(at: clock.now)) != nil {
            lastFullCopyAt = clock.now
        } else {
            notSaved = true
        }
    }
}
