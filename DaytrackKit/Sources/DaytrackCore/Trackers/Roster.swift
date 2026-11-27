import Foundation

/// At most eight trackers on the board; archive is unlimited (rule 8, Q11a).
public enum Roster {
    public static let cap = 8
    public static let fullRefusal = "Eight fit on one board. Archive one to make room."

    public enum Decision: Equatable, Sendable {
        case allowed
        case refused(String)
    }

    /// Whether one more tracker can join the board alongside `trackers`.
    public static func canActivate(alongside trackers: [Tracker]) -> Decision {
        trackers.filter { !$0.isArchived }.count < cap ? .allowed : .refused(fullRefusal)
    }
}
