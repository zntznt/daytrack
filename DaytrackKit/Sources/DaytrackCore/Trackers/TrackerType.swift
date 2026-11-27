import Foundation

/// A tracker's scale. Fixed at creation, and with it the number of stops (rule 6).
public enum TrackerType: String, Codable, Sendable, CaseIterable {
    case numeric, ordinal, binary

    public var stops: Int {
        switch self {
        case .numeric: 11
        case .ordinal: 5
        case .binary: 2
        }
    }

    /// Words a new tracker starts with. Numeric has none: it shows 0–10.
    public var defaultLabels: [String] {
        switch self {
        case .numeric: []
        case .ordinal: ["Absent", "Present", "Mild", "Moderate", "Severe"]
        case .binary: ["No", "Yes"]
        }
    }

    /// The canonical 0–10 value stored for a stop. The index itself is never stored.
    public func value(forIndex index: Int) -> Double {
        precondition((0..<stops).contains(index), "index outside the scale")
        return Double(index) * 10 / Double(stops - 1)
    }

    /// The stop a stored 0–10 value displays as.
    public func index(forValue value: Double) -> Int {
        let i = Int((value / 10 * Double(stops - 1)).rounded())
        return min(max(i, 0), stops - 1)
    }
}
