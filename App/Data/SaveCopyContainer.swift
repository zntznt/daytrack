import DaytrackCore
import SwiftUI
import UniformTypeIdentifiers

/// Wires the full copy to `SaveCopyModel` and `.fileExporter`, or to a direct write under `-uiTestExportTo`.
struct SaveCopyContainer: View {
    let state: AppState
    @State private var model: SaveCopyModel

    init(state: AppState) {
        self.state = state
        _model = State(initialValue: SaveCopyModel(settings: state.settings, deviceState: state.env.deviceState, clock: state.env.clock,
                                                   timeZone: state.env.timeZone, directory: AppEnvironment.exportsDirectory))
    }

    var body: some View {
        SaveCopyView(factLine: Copy.lastFullCopy(model.lastFullCopyAt, now: state.env.clock.now, timeZone: state.env.timeZone, locale: .autoupdatingCurrent),
                     notSavedLine: model.notSaved ? Copy.fullCopyNotSaved : nil,
                     onSave: save)
            .fileExporter(isPresented: Binding(get: { model.pending != nil && state.env.exportTo == nil }, set: { _ in }),
                          item: model.pending.map(WrittenFile.init(url:)),
                          contentTypes: [.json],
                          defaultFilename: model.pending?.lastPathComponent,
                          onCompletion: { model.finish(saved: (try? $0.get()) != nil) },
                          onCancellation: { model.finish(saved: false) })
    }

    private func save() {
        model.prepare(state.store.record)
        guard let exportTo = state.env.exportTo, let pending = model.pending else { return }
        let target = exportTo.appendingPathComponent(pending.lastPathComponent)
        try? FileManager.default.createDirectory(at: exportTo, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: target)
        model.finish(saved: (try? FileManager.default.copyItem(at: pending, to: target)) != nil)
    }
}

/// Hands the already-written file to the exporter as-is.
private struct WrittenFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { SentTransferredFile($0.url) }
            // Without a name the exporter's file wrapper gets nil and throws, which aborted the app on device.
            .suggestedFileName { $0.url.lastPathComponent }
    }
}
