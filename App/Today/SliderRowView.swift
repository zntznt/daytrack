import DaytrackCore
import SwiftUI

/// One tracker on the board, drag mode (HANDOFF §3, §4 Motion). Plain content: no custom glass.
/// The track sets the value on touch-down; the value box is a separate button that opens the pad (decisions Q4).
struct SliderRowView: View {
    let state: RowState
    /// The value under the finger, each time it moves to a new stop.
    let onPreview: (DayValue?) -> Void
    /// The value to write: on release, or on an accessibility step.
    let onCommit: (DayValue?) -> Void
    let onOpenPad: () -> Void
    let onDraggingChanged: (Bool) -> Void

    /// The in-flight drag, measured against the real track width. nil when no finger is down.
    @State private var live: RowState?
    /// Bumped by the stops RowState says were crossed; drives the selection tick.
    @State private var ticks = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var held: Bool { live != nil }

    /// What the row shows now: the finger's stop during a drag, else the committed value.
    private var shown: RowState {
        var s = live ?? state
        s.value = s.commitValue
        return s
    }

    var body: some View {
        // Two lines, at most 72pt, so eight rows fit on one screen (HANDOFF "Eight things, one screen").
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: state.tracker.symbol)
                    .font(.subheadline).foregroundStyle(Tokens.textFaint).frame(width: 18)
                Text(verbatim: state.tracker.name)
                    .typography(.body).foregroundStyle(Tokens.text)
            }
            .accessibilityHidden(true)
            HStack(spacing: 12) {
                track
                valueButton
            }
        }
        // A container for the row's frame only; the track and button stay the accessible elements.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("row.\(state.tracker.name)")
    }

    private var valueButton: some View {
        Button(action: onOpenPad) {
            Group {
                switch shown.value {
                case nil: Text(verbatim: "–").typography(.numericValue).foregroundStyle(Tokens.textFaint)
                case .skip: Text("skipped").typography(.caption).foregroundStyle(Tokens.textFaint)
                case .set:
                    Text(verbatim: shown.accessibilityValue)
                        .typography(state.labels.isEmpty ? .numericValue : .wordValue)
                        .foregroundStyle(held ? Tokens.accent : Tokens.text)
                }
            }
            .frame(minWidth: 58, minHeight: 44, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: state.valueButtonLabel))
    }

    private var track: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let stops = state.tracker.type.stops
            let x = { (stop: Int) in width * CGFloat(stop) / CGFloat(stops - 1) }
            ZStack(alignment: .leading) {
                Capsule().fill(Tokens.surface).frame(height: 9)
                if let stop = shown.currentStop {
                    Capsule().fill(Tokens.accent).frame(width: max(x(stop), 9), height: 9)
                }
                if let y = state.yesterdayStop {
                    Rectangle().fill(Tokens.textSecondary).frame(width: 1.5, height: 6).offset(x: x(y) - 0.75)
                }
                if let stop = shown.currentStop {
                    // Only the handle casts a shadow (HANDOFF §4). It jumps to 1.18 on press and relaxes over 120ms.
                    RoundedRectangle(cornerRadius: 3).fill(Tokens.text).frame(width: 5, height: 23)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                        .animation(held ? nil : .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.12)) { $0.scaleEffect(held ? 1.18 : 1) }
                        .offset(x: x(stop) - 2.5)
                }
            }
            .frame(width: width, height: geo.size.height)
            // The eased 160ms slide plays only on the accessibility step; never under a finger.
            .animation(held || reduceMotion ? nil : .timingCurve(0.22, 1, 0.36, 1, duration: 0.16), value: shown.currentStop)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                if live == nil {
                    live = RowState(tracker: state.tracker, value: state.value, yesterday: state.yesterday,
                                    trackWidth: max(width, 1), mode: state.mode, labels: state.labels)
                    onDraggingChanged(true)
                }
                let before = live?.currentStop
                ticks += live?.drag(toX: g.location.x) ?? 0
                if live?.currentStop != before || before == nil { onPreview(live?.commitValue) }
            }.onEnded { _ in
                guard var done = live else { return }
                done.endDrag()
                onCommit(done.value)
                live = nil
                onDraggingChanged(false)
            })
        }
        .frame(height: 44)
        .sensoryFeedback(.selection, trigger: ticks)
        .accessibilityElement()
        .accessibilityIdentifier("track.\(state.tracker.name)")
        .accessibilityLabel(Text(verbatim: state.tracker.name))
        .accessibilityValue(Text(verbatim: shown.accessibilityValue))
        .accessibilityAdjustableAction { direction in
            var next = state
            if direction == .increment { next.increment() } else if direction == .decrement { next.decrement() }
            if next.value != state.value { onCommit(next.value) }
        }
    }
}
