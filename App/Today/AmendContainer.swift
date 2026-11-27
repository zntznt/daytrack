import DaytrackCore
import SwiftUI

/// Yesterday's board (HANDOFF §3 Amend): the same rows with that day's wording. It stays on that day and turns read-only when it closes.
struct AmendContainer: View {
    let state: AppState
    let onBringBack: () -> Void
    @State private var model: TodayModel

    init(state: AppState, onBringBack: @escaping () -> Void) {
        (self.state, self.onBringBack) = (state, onBringBack)
        let yesterday = LocalCalendar(timeZone: state.env.timeZone).dayKey(for: state.env.clock.now).adding(days: -1)
        _model = State(initialValue: TodayModel(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone, day: yesterday))
    }

    var body: some View {
        BoardContainer(state: state, model: model, onBringBack: onBringBack)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("amend")
            .presentationDetents([.large])
    }
}
