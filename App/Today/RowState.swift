import CoreGraphics
import DaytrackCore

/// How a row takes input (HANDOFF §3). Switching never alters stored data.
enum EntryMode: Sendable {
    case drag, stepper, large
}

/// The slider row's gesture and label logic, kept out of the view so it can be tested (HANDOFF §3, §4 Motion and Haptics).
struct RowState {
    /// One key on the choice pad. `value == nil` leaves the row blank.
    struct PadOption: Hashable {
        let title: String
        let value: DayValue?
    }

    let tracker: Tracker
    /// The committed value; nil is blank.
    var value: DayValue?
    let yesterday: DayValue?
    let trackWidth: CGFloat
    let mode: EntryMode
    /// The words of the day's era (`Eras.labels`); empty for numeric.
    let labels: [String]
    /// The stop under the finger while a drag is live; nil otherwise.
    private(set) var dragStop: Int?

    init(tracker: Tracker, value: DayValue?, yesterday: DayValue?, trackWidth: CGFloat, mode: EntryMode, labels: [String]? = nil) {
        precondition(trackWidth > 0, "the track has a width")
        self.tracker = tracker
        self.value = value
        self.yesterday = yesterday
        self.trackWidth = trackWidth
        self.mode = mode
        self.labels = labels ?? tracker.labels
    }

    private var stops: Int { tracker.type.stops }

    private func index(_ value: DayValue?) -> Int? {
        guard case .set(let v) = value else { return nil }
        return tracker.type.index(forValue: v)
    }

    /// The stop shown now: the finger's during a drag, else the committed one. nil when skipped or blank.
    var currentStop: Int? { dragStop ?? index(value) }

    /// Where yesterday's tick sits; nil unless yesterday was set.
    var yesterdayStop: Int? { index(yesterday) }

    // MARK: Gesture

    /// Press-to-position: the nearest stop to `x`, clamped to the ends.
    func stop(atX x: CGFloat) -> Int {
        let raw = Int((x / trackWidth * CGFloat(stops - 1)).rounded())
        return min(max(raw, 0), stops - 1)
    }

    /// One selection tick per stop crossed.
    func stopsCrossed(from: Int, to: Int) -> Int {
        abs(to - from)
    }

    /// Press or move to `x`. Returns the ticks to play; the press itself positions without a tick.
    mutating func drag(toX x: CGFloat) -> Int {
        let to = stop(atX: x)
        defer { dragStop = to }
        return dragStop.map { stopsCrossed(from: $0, to: to) } ?? 0
    }

    /// What the row writes when the drag ends.
    var commitValue: DayValue? {
        dragStop.map { .set(tracker.type.value(forIndex: $0)) } ?? value
    }

    /// Release: commit, no tick. The value is already where the finger left it.
    mutating func endDrag() {
        value = commitValue
        dragStop = nil
    }

    // MARK: Adjustable

    /// Step one stop up, clamped. Blank and skipped stay as they are: a step must not overwrite a skip or invent a start.
    mutating func increment() { step(1) }

    mutating func decrement() { step(-1) }

    private mutating func step(_ by: Int) {
        guard let i = index(value) else { return }
        value = .set(tracker.type.value(forIndex: min(max(i + by, 0), stops - 1)))
    }

    // MARK: Labels

    /// "{tracker}, {value | skipped | not written yet}. Activate for choices" (decisions Q4).
    var valueButtonLabel: String {
        Copy.valueLabel(tracker, value: value, labels: labels)
    }

    /// The word, the number, "skipped" or "not written yet".
    /// shortcut: sliced from `Copy.valueLabel` because Copy has no bare value string yet; move it into Copy when Copy is next in scope.
    var accessibilityValue: String {
        String(valueButtonLabel.dropFirst(tracker.name.count + 2).dropLast(Self.labelTail.count))
    }

    private static let labelTail = ". Activate for choices"

    /// The stops, "Skip {tracker}", and "Leave {tracker} blank" only when the row is set or skipped (decisions Q4).
    var padOptions: [PadOption] {
        var options = (0..<stops).map { i in
            PadOption(title: labels.isEmpty ? String(i) : labels[i], value: .set(tracker.type.value(forIndex: i)))
        }
        options.append(PadOption(title: Copy.skipKey(tracker.name), value: .skip))
        if value != nil { options.append(PadOption(title: Copy.leaveBlankKey(tracker.name), value: nil)) }
        return options
    }
}
