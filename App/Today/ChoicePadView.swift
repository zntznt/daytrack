import DaytrackCore
import SwiftUI

/// The choice pad (decisions Q4, HANDOFF §4 "Tap path"). Shown in a native sheet, which supplies the glass; no custom `glassEffect`.
/// Each key reports once; the presenter writes and closes in the same transaction, with animations disabled.
struct ChoicePadView: View {
    /// `RowState.padOptions`: the stops, "Skip {tracker}", and "Leave {tracker} blank" when set or skipped.
    let options: [RowState.PadOption]
    /// False once the day has closed: clearing to blank is no longer offered.
    let dayIsOpen: Bool
    let onChoose: (RowState.PadOption) -> Void

    private var stops: [RowState.PadOption] { options.filter { if case .set = $0.value { true } else { false } } }
    private var others: [RowState.PadOption] {
        options.filter { option in
            switch option.value {
            case .set: false
            case .skip: true
            case nil: dayIsOpen
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
                ForEach(stops, id: \.self) { key($0) }
            }
            ForEach(others, id: \.self) { key($0) }
        }
        .padding(22)
        .tint(Tokens.accent)
        .controlSize(.large)
    }

    private func key(_ option: RowState.PadOption) -> some View {
        Button { onChoose(option) } label: {
            Text(verbatim: option.title).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
    }
}
