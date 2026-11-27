#if DEBUG
import DaytrackCore
import SwiftUI

/// Screens opened directly by `-uiTestScreen <name>`. Later tasks add their screens here.
enum DebugScreens {
    @ViewBuilder static func view(for screen: String) -> some View {
        switch screen {
        case "catalog": CatalogView()
        case "sliderRows": SliderRowCatalog()
        case "choicePad": ChoicePadCatalog()
        default: Text(verbatim: "No debug screen named \(screen)")
        }
    }
}

/// DEBUG: the slider rows, with the choice pad in a sheet and the last chosen key shown as `pad.last`.
private struct ChoicePadCatalog: View {
    @State private var rows = SliderRowCatalog.seeded
    @State private var padRow: Int?
    @State private var last = "none"

    /// The pad opens and closes with no transition (HANDOFF §4 "Tap path").
    private func instantly(_ change: () -> Void) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t, change)
    }

    var body: some View {
        VStack(spacing: 18) {
            ForEach(rows.indices, id: \.self) { i in
                SliderRowView(state: rows[i], onPreview: { _ in }, onCommit: { rows[i].value = $0 },
                              onOpenPad: { instantly { padRow = i } }, onDraggingChanged: { _ in })
            }
            Text(verbatim: last).accessibilityIdentifier("pad.last")
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
        .sheet(isPresented: Binding(get: { padRow != nil }, set: { if !$0 { padRow = nil } })) {
            if let i = padRow {
                ChoicePadView(options: rows[i].padOptions, dayIsOpen: true) { option in
                    switch option.value {
                    case nil: last = "blank"
                    case .skip: last = "skip"
                    case .set(let v): last = "set \(v)"
                    }
                    instantly {
                        rows[i].value = option.value
                        padRow = nil
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

/// DEBUG: one slider row of each type. Numeric starts blank, ordinal set, binary skipped.
private struct SliderRowCatalog: View {
    private static let day = DayKey(year: 2026, month: 1, day: 1)!
    // trackWidth is a placeholder: the view measures the real track for gestures.
    private static let seeds: [(StarterTemplate, DayValue?, DayValue?)] = [
        (StarterCatalog.all[0], nil, .set(6)),
        (StarterCatalog.all[6], .set(5), .set(2.5)),
        (StarterCatalog.all[7], .skip, .set(10)),
    ]
    @State private var rows = seeded
    static let seeded: [RowState] = seeds.map { s, value, yesterday in
        RowState(tracker: Tracker(name: s.name, symbol: s.symbol, type: s.type, createdAt: day),
                 value: value, yesterday: yesterday, trackWidth: 300, mode: .drag)
    }

    var body: some View {
        VStack(spacing: 18) {
            ForEach(rows.indices, id: \.self) { i in
                SliderRowView(state: rows[i], onPreview: { _ in }, onCommit: { rows[i].value = $0 },
                              onOpenPad: {}, onDraggingChanged: { _ in })
            }
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }
}
#endif
