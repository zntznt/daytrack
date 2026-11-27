import DaytrackCore
import SwiftUI

/// Wires the board to `TodayModel`, and presents the choice pad in a native sheet.
struct TodayContainer: View {
    let state: AppState
    let onBringBack: () -> Void
    @State private var model: TodayModel
    @State private var padTracker: Tracker?

    init(state: AppState, onBringBack: @escaping () -> Void) {
        self.state = state
        self.onBringBack = onBringBack
        _model = State(initialValue: TodayModel(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone))
    }

    /// The pad opens and closes with no transition (HANDOFF §4 "Tap path").
    private func instantly(_ change: () -> Void) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t, change)
    }

    var body: some View {
        TodayView(dayName: model.dayName, dayID: model.day.isoString, rows: model.rows,
                  dotStripLabel: Copy.dotStrip(model.counts), isBoardEmpty: model.isBoardEmpty, isDayOne: model.isDayOne,
                  skipRestTitle: model.skipRestTitle,
                  onCommit: { model.commit($1, to: $0) },
                  onOpenPad: { tracker in instantly { padTracker = tracker } },
                  onDraggingChanged: { model.isDragging = $0 },
                  onSkipRest: model.skipRest,
                  onBringBack: onBringBack)
            .onChange(of: state.store.record) { model.receive($1) }
            .sheet(isPresented: Binding(get: { padTracker != nil }, set: { if !$0 { padTracker = nil } })) {
                if let row = model.rows.first(where: { $0.tracker.id == padTracker?.id }) {
                    ChoicePadView(options: row.padOptions, dayIsOpen: model.isOpen) { option in
                        instantly {
                            model.commit(option.value, to: row.tracker)
                            padTracker = nil
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
    }
}
