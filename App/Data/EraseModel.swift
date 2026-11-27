import DaytrackCore
import Foundation

/// Erase everything, export temp files included: nothing Daytrack wrote is left behind (HANDOFF §3, Q2 amendment 2).
/// Files the user saved elsewhere are out of reach and never touched.
struct EraseModel {
    let eraser: Eraser
    let exportsDirectory: URL

    func erase() throws {
        try? FileManager.default.removeItem(at: exportsDirectory)
        try eraser.eraseAll()
    }
}
