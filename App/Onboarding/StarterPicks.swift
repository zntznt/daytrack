import DaytrackCore

/// The onboarding selection: one to eight starters, in the order tapped (Q11a, Q11b).
struct StarterPicks: Equatable {
    static let noPickReason = "Pick at least one"

    private(set) var picked: [StarterTemplate] = []
    /// Set when a ninth pick is refused; cleared once there is room again.
    private(set) var refusal: String?

    var canStart: Bool { !picked.isEmpty }

    /// What the line under the Start button says, if anything.
    var reason: String? { refusal ?? (canStart ? nil : Self.noPickReason) }

    mutating func toggle(_ starter: StarterTemplate) {
        if let i = picked.firstIndex(of: starter) {
            picked.remove(at: i)
            refusal = nil
        } else if picked.count < Roster.cap {
            picked.append(starter)
        } else {
            refusal = Roster.fullRefusal
        }
    }
}
