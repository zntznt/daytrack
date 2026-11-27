import SwiftUI

/// Settings' reminder rows (decisions Q10). Plain values and closures only.
struct ReminderSettingsView: View {
    let isOn: Bool
    let isDenied: Bool
    /// The chosen time as a date on a fixed GMT day; only its hour and minute count.
    let time: Date
    let scheduledLine: String
    let horizonLine: String
    let nothingTonight: Bool
    let onToggle: (Bool) -> Void
    let onPickTime: (Date) -> Void

    var body: some View {
        // A refusal is final here: the toggle stops asking and the line points to system settings.
        Toggle("Daily reminder", isOn: Binding(get: { isOn }, set: onToggle))
            .disabled(isDenied)
            .accessibilityIdentifier("settings.reminder")
        DatePicker("At", selection: Binding(get: { time }, set: onPickTime), displayedComponents: .hourAndMinute)
            // 24-hour, like every time in the app's copy.
            .environment(\.locale, Locale(identifier: "en_GB"))
            .environment(\.timeZone, .gmt)
            .accessibilityIdentifier("settings.reminderTime")
        if isDenied {
            Text(verbatim: ReminderSettingsModel.deniedLine).accessibilityIdentifier("settings.reminderDenied")
        } else if isOn {
            Text(verbatim: scheduledLine).accessibilityIdentifier("settings.reminderScheduled")
            if nothingTonight { Text("Nothing arrives tonight") }
            Text(verbatim: horizonLine).font(.footnote)
        }
    }
}
