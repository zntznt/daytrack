import DaytrackCore
import SwiftUI

/// The board (HANDOFF §3 Today). Plain content rows, no glass; system buttons only.
struct TodayView: View {
    let dayName: String
    /// The day as "YYYY-MM-DD", the day name's accessibility identifier.
    let dayID: String
    let rows: [RowState]
    let dotStripLabel: String
    let isBoardEmpty: Bool
    let isDayOne: Bool
    /// nil hides the day action.
    let skipRestTitle: String?
    let onCommit: (Tracker, DayValue?) -> Void
    let onOpenPad: (Tracker) -> Void
    let onDraggingChanged: (Bool) -> Void
    let onSkipRest: () -> Void
    let onBringBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: dayName)
                    .typography(.dayName).foregroundStyle(Tokens.text)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(dayID)
                if isBoardEmpty {
                    BoardEmptyView(onBringBack: onBringBack)
                } else {
                    board
                }
            }
            .padding(.horizontal, 22)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var board: some View {
        DotStripView(values: rows.map(\.value), label: dotStripLabel)
        if isDayOne {
            // No "tap the number to skip" hint: the value button's label carries skip on every row (decisions Q4).
            Text("Drag any track to set it.").typography(.caption).foregroundStyle(Tokens.textSecondary)
        }
        VStack(spacing: 0) {
            ForEach(rows, id: \.tracker.id) { row in
                SliderRowView(state: row, onPreview: { _ in }, onCommit: { onCommit(row.tracker, $0) },
                              onOpenPad: { onOpenPad(row.tracker) }, onDraggingChanged: onDraggingChanged)
            }
        }
        if let skipRestTitle {
            Button(skipRestTitle, action: onSkipRest)
                .buttonStyle(.glass)
                .tint(Tokens.accent)
        }
    }
}
