import DaytrackCore
import SwiftUI

/// Wires the board to `TodayModel`, and presents the choice pad in a native sheet.
struct TodayContainer: View {
    let state: AppState
    let onBringBack: () -> Void
    @State private var model: TodayModel
    @State private var padTracker: Tracker?

    init(state: AppState, onBringBack: @escaping () -> Void) {
        (self.state, self.onBringBack) = (state, onBringBack)
        _model = State(initialValue: TodayModel(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone))
    }

    var body: some View {
        TodayView(dayName: model.dayName, dayID: model.day.isoString, rows: model.rows,
                  dotStripLabel: Copy.dotStrip(model.counts), isBoardEmpty: model.isBoardEmpty, isDayOne: model.isDayOne,
                  skipRestTitle: model.skipRestTitle, onCommit: { model.commit($1, to: $0) },
                  onOpenPad: { tracker in withTransaction(\.disablesAnimations, true) { padTracker = tracker } },
                  onDraggingChanged: { model.isDragging = $0 }, onSkipRest: model.skipRest, onBringBack: onBringBack)
            .onChange(of: state.store.record) { model.receive($1) }
            .sheet(item: $padTracker) { tracker in
                if let row = model.rows.first(where: { $0.tracker.id == tracker.id }) {
                    ChoicePadView(options: row.padOptions, dayIsOpen: model.isOpen) { option in
                        // The pad opens and closes with no transition (HANDOFF §4 "Tap path").
                        withTransaction(\.disablesAnimations, true) {
                            model.commit(option.value, to: row.tracker)
                            padTracker = nil
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
    }
}
