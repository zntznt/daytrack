import DaytrackCore
import SwiftUI

/// Wires Settings › Data › Erase everything to `EraseModel`. `onErased` shows the Erased screen.
struct EraseContainer: View {
    let state: AppState
    let onErased: () -> Void
    @State private var asking = false

    var body: some View {
        EraseView(confirm: asking ? Copy.eraseConfirm(state.store.record) : nil, noOtherCopy: Copy.eraseNoOtherCopy,
                  onAsk: { asking = true }, onKeep: { asking = false }, onErase: erase)
    }

    private func erase() {
        let eraser = Eraser(recorder: state.recorder, store: state.env.records, deviceState: state.env.deviceState,
                            reminders: state.env.reminders)
        if (try? EraseModel(eraser: eraser, exportsDirectory: AppEnvironment.exportsDirectory).erase()) != nil { onErased() }
    }
}
