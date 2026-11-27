import DaytrackCore
import SwiftUI

/// Today's board. Runs the `DayTicker`, opens yesterday's board from the amend chip, and offers the reminder after day one.
struct TodayContainer: View {
    let state: AppState
    let onBringBack: () -> Void
    @State private var model: TodayModel
    @State private var ticker: DayTicker
    @State private var dayOne: DayOneWrittenModel
    @State private var reminder: ReminderSettingsModel
    @State private var amending = false
    @Environment(\.scenePhase) private var phase

    init(state: AppState, onBringBack: @escaping () -> Void) {
        (self.state, self.onBringBack) = (state, onBringBack)
        let model = TodayModel(recorder: state.recorder, clock: state.env.clock, tz: state.env.timeZone)
        _model = State(initialValue: model)
        _ticker = State(initialValue: DayTicker(clock: state.env.clock, tz: state.env.timeZone,
                                                lockHour: { [recorder = state.recorder] in recorder.record.settings.lockHour },
                                                onBoundary: model.tick))
        _dayOne = State(initialValue: DayOneWrittenModel(deviceState: state.env.deviceState))
        _reminder = State(initialValue: ReminderSettingsModel(state: state))
    }

    var body: some View {
        BoardContainer(state: state, model: model, onBringBack: onBringBack, onAmend: { amending = true })
            .onAppear { ticker.refresh() }
            .onChange(of: phase) { if $1 == .active { ticker.refresh() } }
            .sheet(isPresented: $amending) { AmendContainer(state: state, onBringBack: { amending = false; onBringBack() }) }
            .onChange(of: model.record, initial: true) { dayOne.receive($1, today: model.day) }
            .safeAreaInset(edge: .bottom) {
                if dayOne.isShowing {
                    DayOneWrittenView(remindTitle: reminder.remindTitle,
                                      onRemind: { Task { await reminder.setOn(true); dayOne.dismiss() } },
                                      onNoReminder: { Task { await reminder.setOn(false); dayOne.dismiss() } })
                }
            }
    }
}

/// One day's board wired to its `TodayModel`, with the choice pad in a native sheet. Today and Amend both use it.
struct BoardContainer: View {
    let state: AppState
    let model: TodayModel
    let onBringBack: () -> Void
    var onAmend: () -> Void = {}
    @State private var padTracker: Tracker?
    @State private var noteDay: DayKey?

    var body: some View {
        TodayView(dayName: model.dayName, dayID: model.day.isoString, rows: model.rows,
                  dotStripLabel: Copy.dotStrip(model.counts), isBoardEmpty: model.isBoardEmpty, isDayOne: model.isDayOne,
                  isOpen: model.isOpen, amendChip: model.amendChip,
                  skipRestTitle: model.skipRestTitle, noteTeaser: noteTeaser, onCommit: { model.commit($1, to: $0) },
                  onOpenPad: { tracker in withTransaction(\.disablesAnimations, true) { padTracker = tracker } },
                  onDraggingChanged: { model.isDragging = $0 }, onSkipRest: model.skipRest, onBringBack: onBringBack,
                  onAmend: onAmend, onOpenNote: { noteDay = model.day })
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
            .sheet(isPresented: Binding(get: { noteDay != nil }, set: { if !$0 { noteDay = nil } })) {
                if let noteDay { NoteContainer(state: state, model: model, day: noteDay, onDone: { self.noteDay = nil }) }
            }
    }

    /// The note itself, or the prompt to add one while the day is open (prototype noteTeaser).
    private var noteTeaser: String? {
        if let note = model.record.entries[model.day]?.note { return note }
        guard model.isOpen else { return nil }
        let today = LocalCalendar(timeZone: state.env.timeZone).dayKey(for: state.env.clock.now)
        return model.day == today ? "Add a note" : "Add a note to yesterday"
    }
}
