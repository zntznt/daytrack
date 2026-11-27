import DaytrackCore
import SwiftUI

/// One day's note, saved through `Recorder` shortly after typing stops and again on disappear.
/// It stays on the day it opened and turns read-only when that day closes.
struct NoteContainer: View {
    let state: AppState
    let model: TodayModel
    let day: DayKey
    let onDone: () -> Void
    @State private var text: String

    init(state: AppState, model: TodayModel, day: DayKey, onDone: @escaping () -> Void) {
        (self.state, self.model, self.day, self.onDone) = (state, model, day, onDone)
        _text = State(initialValue: model.record.entries[day]?.note ?? "")
    }

    var body: some View {
        let tz = state.env.timeZone, s = model.record.settings
        let status = DayClosing.status(of: day, now: state.env.clock.now, lockHour: s.lockHour, closedThrough: s.closedThrough, tz: tz)
        let isOpen = status == .today || { if case .yesterdayOpen = status { true } else { false } }()
        let footer = isOpen
            ? Copy.noteFooter(closeInstant: DayClosing.closeInstant(day, lockHour: s.lockHour, tz: tz), timeZone: tz, locale: .autoupdatingCurrent)
            : "Written with the day. It travels in every export."
        // Once closed it shows what is stored, not text the close refused.
        let shown = isOpen ? $text : .constant(model.record.entries[day]?.note ?? "")
        NoteView(title: model.dayName, text: shown, isEditable: isOpen, footer: footer, onDone: onDone)
            .task(id: text) {
                try? await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled { save() }
            }
            .onDisappear(perform: save)
    }

    /// Only a changed note is a write (Q3). A closed day refuses it and the store stays as written.
    private func save() {
        guard text != (state.recorder.record.entries[day]?.note ?? "") else { return }
        try? state.recorder.setNote(text, on: day)
    }
}
