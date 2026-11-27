import DaytrackCore
import SwiftUI

/// Today's board. Runs the `DayTicker` and opens yesterday's board from the amend chip.
struct TodayContainer: View {
    let state: AppState
    let onBringBack: () -> Void
    @State private var model: TodayModel
    @State private var ticker: DayTicker
    @State private var amending = false
    @Environment(\.scenePhase) private var phase

    init(state: AppState, onBringBack: @escaping () -> Void) {
        (self.state, self.onBringBack) = (state, onBringBack)
        let model = TodayModel(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone)
        _model = State(initialValue: model)
        _ticker = State(initialValue: DayTicker(clock: state.env.clock, tz: state.env.timeZone,
                                                lockHour: { [recorder = state.recorder] in recorder.record.settings.lockHour },
                                                onBoundary: model.tick))
    }

    var body: some View {
        BoardContainer(state: state, model: model, onBringBack: onBringBack, onAmend: { amending = true })
            .onAppear { ticker.refresh() }
            .onChange(of: phase) { if $1 == .active { ticker.refresh() } }
            .sheet(isPresented: $amending) { AmendContainer(state: state, onBringBack: { amending = false; onBringBack() }) }
    }
}

/// One day's board wired to its `TodayModel`, with the choice pad in a native sheet. Today and Amend both use it.
struct BoardContainer: View {
    let state: AppState
    let model: TodayModel
    let onBringBack: () -> Void
    var onAmend: () -> Void = {}
    @State private var padTracker: Tracker?

    var body: some View {
        TodayView(dayName: model.dayName, dayID: model.day.isoString, rows: model.rows,
                  dotStripLabel: Copy.dotStrip(model.counts), isBoardEmpty: model.isBoardEmpty, isDayOne: model.isDayOne,
                  isOpen: model.isOpen, amendChip: model.amendChip,
                  skipRestTitle: model.skipRestTitle, onCommit: { model.commit($1, to: $0) },
                  onOpenPad: { tracker in withTransaction(\.disablesAnimations, true) { padTracker = tracker } },
                  onDraggingChanged: { model.isDragging = $0 }, onSkipRest: model.skipRest, onBringBack: onBringBack,
                  onAmend: onAmend)
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
