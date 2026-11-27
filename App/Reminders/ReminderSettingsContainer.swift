import DaytrackCore
import SwiftUI

/// Wires the reminder rows to `ReminderSettingsModel`.
struct ReminderSettingsContainer: View {
    @State private var model: ReminderSettingsModel

    init(state: AppState) { _model = State(initialValue: ReminderSettingsModel(state: state)) }

    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .gmt
        return c
    }

    var body: some View {
        let t = model.time
        ReminderSettingsView(isOn: model.isOn, isDenied: model.isDenied,
                             time: Self.calendar.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: t.hour, minute: t.minute))!,
                             scheduledLine: model.scheduledLine, horizonLine: Copy.reminderHorizon, nothingTonight: model.nothingTonight,
                             onToggle: { on in Task { await model.setOn(on) } },
                             onPickTime: { date in
                                 let c = Self.calendar.dateComponents([.hour, .minute], from: date)
                                 model.setTime(Settings.ReminderTime(hour: c.hour ?? 0, minute: c.minute ?? 0))
                             })
            .task { await model.refresh() }
    }
}

extension ReminderSettingsModel {
    convenience init(state: AppState) {
        self.init(settings: state.settings, asker: PermissionAsker(client: state.env.notifications),
                  record: { [store = state.store] in store.record }, clock: state.env.clock, tz: state.env.timeZone)
    }
}
