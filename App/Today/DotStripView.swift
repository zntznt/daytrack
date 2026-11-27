import DaytrackCore
import SwiftUI

/// One segment per active row: written, skipped and blank each look different (decisions Q5). Plain content.
struct DotStripView: View {
    /// Each row's value in board order; nil is blank.
    let values: [DayValue?]
    /// `Copy.dotStrip`: "n written, k skipped, b still blank".
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(values.indices, id: \.self) { i in
                Capsule().fill(color(values[i])).frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityIdentifier("dotStrip")
    }

    private func color(_ value: DayValue?) -> Color {
        switch value {
        case .set: Tokens.accent
        case .skip: Tokens.textFaint
        case nil: Tokens.textFaint.opacity(0.25)
        }
    }
}
