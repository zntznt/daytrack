import SwiftUI

/// Settings › Data rows for the full copy. Plain values and closures only.
struct SaveCopyView: View {
    let factLine: String
    let notSavedLine: String?
    let onSave: () -> Void

    var body: some View {
        Button("Save a full copy (JSON)", action: onSave)
            .accessibilityIdentifier("settings.saveCopy")
        if let notSavedLine {
            Text(verbatim: notSavedLine)
                .accessibilityIdentifier("settings.saveCopyNotSaved")
        }
        Text(verbatim: factLine)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("settings.lastFullCopy")
    }
}
