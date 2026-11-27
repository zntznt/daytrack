import Foundation

extension Copy {
    // MARK: Erase (HANDOFF §3, decisions Q2 amendment 2)

    /// The confirm, with the real counts: "40 days, 2 notes and 3 trackers. This cannot be undone."
    /// A day counts once it holds a value, a skip or a note.
    public static func eraseConfirm(_ record: Record) -> String {
        let days = record.entries.values.filter { !$0.values.isEmpty || $0.note != nil }.count
        let notes = record.entries.values.filter { $0.note != nil }.count
        return "\(counted(days, "day")), \(counted(notes, "note")) and \(counted(record.trackers.count, "tracker")). This cannot be undone."
    }

    public static let eraseNoOtherCopy = "Daytrack keeps no other copy. Files you saved yourself are not touched; Daytrack cannot see them."

    private static func counted(_ n: Int, _ noun: String) -> String { "\(n) \(noun)\(n == 1 ? "" : "s")" }
}
