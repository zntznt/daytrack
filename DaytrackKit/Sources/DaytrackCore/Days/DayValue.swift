import Foundation

/// One tracker's value on one day. A missing key in `DayEntry.values` means blank (rule 3).
public enum DayValue: Hashable, Sendable {
    /// A canonical 0–10 value.
    case set(Double)
    /// The user asserted nothing happened worth writing.
    case skip
}
