import Foundation

/// A starting point for a new tracker. Not a tracker: it has no id and no days (Q11b).
public struct StarterTemplate: Hashable, Sendable {
    public let name: String
    public let symbol: String
    public let type: TrackerType
}

public enum StarterCatalog {
    public static let all: [StarterTemplate] = [
        StarterTemplate(name: "Sleep", symbol: "moon.fill", type: .numeric),
        StarterTemplate(name: "Energy", symbol: "bolt.fill", type: .numeric),
        StarterTemplate(name: "Focus", symbol: "scope", type: .numeric),
        StarterTemplate(name: "Mood", symbol: "face.smiling", type: .numeric),
        StarterTemplate(name: "Movement", symbol: "figure.run", type: .numeric),
        StarterTemplate(name: "Work", symbol: "briefcase.fill", type: .numeric),
        StarterTemplate(name: "Anxiety", symbol: "wind", type: .ordinal),
        StarterTemplate(name: "Meds taken", symbol: "pills.fill", type: .binary),
        StarterTemplate(name: "Eating", symbol: "fork.knife", type: .numeric),
        StarterTemplate(name: "Home", symbol: "house.fill", type: .numeric),
        StarterTemplate(name: "People", symbol: "person.2.fill", type: .numeric),
    ]
}
