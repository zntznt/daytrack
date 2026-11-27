import DaytrackCore
import SwiftUI

/// Wires the reminder rows to `ReminderSettingsModel`. The picker's date is a fixed GMT day; only hour and minute count.
struct ReminderSettingsContainer: View {
    @State private var model: ReminderSettingsModel

    init(state: AppState) { _model = State(initialValue: ReminderSettingsModel(state: state)) }

    var body: some View {
        let day = Date(timeIntervalSinceReferenceDate: 0)
        ReminderSettingsView(isOn: model.isOn, isDenied: model.isDenied,
                             time: day.addingTimeInterval(TimeInterval(model.time.hour * 3600 + model.time.minute * 60)),
                             scheduledLine: model.scheduledLine, horizonLine: Copy.reminderHorizon, nothingTonight: model.nothingTonight,
                             onToggle: { on in Task { await model.setOn(on) } },
                             onPickTime: { date in
                                 let minutes = (Int(date.timeIntervalSince(day)) / 60 % 1440 + 1440) % 1440
                                 model.setTime(Settings.ReminderTime(hour: minutes / 60, minute: minutes % 60))
                             })
            .task { await model.refresh() }
    }
}

extension ReminderSettingsModel {
    convenience init(state: AppState) {
        self.init(settings: state.settings, client: state.env.notifications,
                  record: { [store = state.store] in store.record }, clock: state.env.clock, tz: state.env.timeZone)
    }
}
