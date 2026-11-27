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
    /// The day's note, or "Add a note"; nil hides the row.
    let noteTeaser: String?
    let onCommit: (Tracker, DayValue?) -> Void
    let onOpenPad: (Tracker) -> Void
    let onDraggingChanged: (Bool) -> Void
    let onSkipRest: () -> Void, onBringBack: () -> Void, onAmend: () -> Void, onOpenNote: () -> Void

    /// The scroll view's visible height, the whole content's height, and the rows' share of it.
    @State private var viewport: CGFloat = 0
    @State private var content: CGFloat = 0
    @State private var rowsHeight: CGFloat = 0

    /// The free board height split across the rows, clamped to 72–112pt (decisions "Board density").
    private var rowHeight: CGFloat {
        guard !rows.isEmpty, viewport > 0 else { return 72 }
        return min(max((viewport - (content - rowsHeight)) / CGFloat(rows.count), 72), 112)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.m) {
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
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { content = $0 }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height - $0.safeAreaInsets.top - $0.safeAreaInsets.bottom }) { viewport = $0 }
        .scrollBounceBehavior(.basedOnSize)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var board: some View {
        DotStripView(values: rows.map(\.value), label: dotStripLabel)
            // At least 16pt clear of the first row, on top of the stack's spacing.
            .padding(.bottom, Tokens.Space.l - Tokens.Space.m)
        if isDayOne {
            // No "tap the number to skip" hint: the value button's label carries skip on every row (decisions Q4).
            Text("Drag any track to set it.").typography(.caption).foregroundStyle(Tokens.textSecondary)
        }
        VStack(spacing: 0) {
            ForEach(rows, id: \.tracker.id) { row in
                SliderRowView(state: row, height: rowHeight, onPreview: { _ in }, onCommit: { onCommit(row.tracker, $0) },
                              onOpenPad: { onOpenPad(row.tracker) }, onDraggingChanged: onDraggingChanged)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { rowsHeight = $0 }
        .disabled(!isOpen)
        if let skipRestTitle {
            Button(skipRestTitle, action: onSkipRest)
                .buttonStyle(.glass)
                .tint(Tokens.accent)
        }
        if let noteTeaser {
            // Outside the disabled rows: a closed day's note still opens, read-only.
            Button(action: onOpenNote) {
                Label { Text(verbatim: noteTeaser).lineLimit(2) } icon: { Image(systemName: "square.and.pencil") }
                    .typography(.body).foregroundStyle(Tokens.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("noteRow")
        }
    }
}
