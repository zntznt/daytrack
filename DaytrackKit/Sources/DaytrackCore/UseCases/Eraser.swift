import Foundation

/// Erase everything (HANDOFF §3, decisions Q2 amendment 2): the record, Settings, `closedThrough` and every DeviceState field.
/// Files the user saved are out of reach and never touched.
public final class Eraser {
    private let recorder: Recorder
    private let store: RecordStore
    private let deviceState: DeviceStateStore
    private let reminders: ReminderScheduling

    /// `store` is the one that owns the files, not a wrapper the Recorder may save through.
    public init(recorder: Recorder, store: RecordStore, deviceState: DeviceStateStore, reminders: ReminderScheduling) {
        self.recorder = recorder
        self.store = store
        self.deviceState = deviceState
        self.reminders = reminders
    }

    public func eraseAll() throws {
        // Through the Recorder so its in-memory record is empty too; the commit publishes the widget with the empty record.
        try recorder.commit { record, _ in record = Record() }
        try deviceState.save(DeviceState())
        // Last, so the commit's save above leaves no file behind.
        try store.eraseAll()
        reminders.removeAll()
    }
}
