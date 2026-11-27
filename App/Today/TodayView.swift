import DaytrackCore
import SwiftUI

/// The board (HANDOFF §3 Today). Plain content rows, no glass; system buttons only.
struct TodayView: View {
    /// `dayID` is the day as "YYYY-MM-DD", the day name's accessibility identifier.
    let dayName: String, dayID: String
    let rows: [RowState]
    let dotStripLabel: String
    let isBoardEmpty: Bool, isDayOne: Bool
    /// False once the day has closed: the rows stop taking input.
    let isOpen: Bool
    /// nil hides the amend chip.
    let amendChip: String?
    /// nil hides the day action.
    let skipRestTitle: String?
    let onCommit: (Tracker, DayValue?) -> Void
    let onOpenPad: (Tracker) -> Void
    let onDraggingChanged: (Bool) -> Void
    let onSkipRest: () -> Void, onBringBack: () -> Void, onAmend: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(verbatim: dayName)
                        .typography(.dayName).foregroundStyle(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(dayID)
                    Spacer()
                    if let amendChip { AmendChipView(title: amendChip, onTap: onAmend) }
                }
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
        .disabled(!isOpen)
        if let skipRestTitle {
            Button(skipRestTitle, action: onSkipRest)
                .buttonStyle(.glass)
                .tint(Tokens.accent)
        }
    }
}
