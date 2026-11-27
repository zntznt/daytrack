import Foundation

public enum LockHourResult: Hashable, Sendable {
    case applied
    /// Lowering would close yesterday at once; nothing changed until `confirmLockHour` (Q1).
    case needsConfirm
}

/// Settings changes. Record settings go through the Recorder pipeline; DeviceState is written directly.
public final class SettingsService {
    private let recorder: Recorder
    private let deviceState: DeviceStateStore

    public init(recorder: Recorder, deviceState: DeviceStateStore) {
        self.recorder = recorder
        self.deviceState = deviceState
    }

    public func setLockHour(_ hour: Int) throws -> LockHourResult {
        if recorder.lockHourChange(to: hour) == .closesYesterdayNow { return .needsConfirm }
        try recorder.applyLockHour(hour)
        return .applied
    }

    public func confirmLockHour(_ hour: Int) throws {
        try recorder.applyLockHour(hour)
    }

    public func setReminderAt(_ time: Settings.ReminderTime?) throws {
        try recorder.commit { record, _ in record.settings.reminderAt = time }
    }

    /// Only this phone's state changes; the record is not saved and nothing is published.
    public func recordFullCopySaved(at date: Date) throws {
        var state = try deviceState.load()
        state.lastFullCopyAt = date
        try deviceState.save(state)
    }
}
