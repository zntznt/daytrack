import Foundation

/// Every user-facing string that depends on data. Views never build these themselves (design-review High 1).
public enum Copy {
    // MARK: Close time (decisions Q1)

    /// The amend chip: "until Fri 20:00". `closeInstant` comes from `DayClosing.closeInstant`.
    public static func amendChip(closeInstant: Date, timeZone: TimeZone, locale: Locale) -> String {
        "until \(closeTime(closeInstant, timeZone: timeZone, locale: locale))"
    }

    /// The note footer names the same close time as the chip (design-review Low 2).
    public static func noteFooter(closeInstant: Date, timeZone: TimeZone, locale: Locale) -> String {
        "Editable until \(closeTime(closeInstant, timeZone: timeZone, locale: locale)), then it is written like the numbers."
    }

    /// The value beside Settings' "Yesterday stays open until".
    public static func settingsLockHour(_ lockHour: Int) -> String {
        precondition((0...23).contains(lockHour), "lock hour is 0 to 23")
        let hour = String(format: "%02d:00", lockHour)
        return lockHour == 0 ? "\(hour) · no grace day" : hour
    }

    // MARK: Board (decisions Q4, Q5)

    /// The dot strip and its accessibility label: "6 written, 2 skipped, 1 still blank".
    public static func dotStrip(_ counts: RowCounts) -> String {
        "\(counts.written) written, \(counts.skipped) skipped, \(counts.blank) still blank"
    }

    /// The value button's accessibility label. `labels` are the words of the day's era (`Eras.labels`); empty for numeric.
    public static func valueLabel(_ tracker: Tracker, value: DayValue?, labels: [String]) -> String {
        let said: String
        switch value {
        case nil: said = "not written yet"
        case .skip: said = "skipped"
        case .set(let v):
            let index = tracker.type.index(forValue: v)
            said = labels.isEmpty ? String(index) : labels[index]
        }
        return "\(tracker.name), \(said). Activate for choices"
    }

    public static func skipKey(_ trackerName: String) -> String {
        "Skip \(trackerName)"
    }

    public static func leaveBlankKey(_ trackerName: String) -> String {
        "Leave \(trackerName) blank"
    }

    /// "Skip the rest of today". `dayLabel` comes from `dayLabel(for:now:timeZone:)`.
    public static func skipRest(dayLabel: String) -> String {
        "Skip the rest of \(dayLabel)"
    }

    /// "today" or "yesterday"; nil for any other day.
    public static func dayLabel(for day: DayKey, now: Date, timeZone: TimeZone) -> String? {
        switch day.days(to: LocalCalendar(timeZone: timeZone).dayKey(for: now)) {
        case 0: "today"
        case 1: "yesterday"
        default: nil
        }
    }

    // MARK: Full copy (decisions Q2)

    /// "Last full copy: 12 Jul (11 days ago)", or "No copy saved yet".
    public static func lastFullCopy(_ at: Date?, now: Date, timeZone: TimeZone, locale: Locale) -> String {
        guard let at else { return "No copy saved yet" }
        let cal = LocalCalendar(timeZone: timeZone)
        let ago = cal.dayKey(for: at).days(to: cal.dayKey(for: now))
        let when = switch ago {
        case 0: "today"
        case 1: "1 day ago"
        default: "\(ago) days ago"
        }
        return "Last full copy: \(format(at, "d MMM", timeZone: timeZone, locale: locale)) (\(when))"
    }

    /// Under the button after the exporter closed without saving (HANDOFF §8: "Cancel is a no-op and says so").
    public static let fullCopyNotSaved = "Not saved. Nothing changed."

    // MARK: Helpers

    /// "Fri 20:00": locale weekday abbreviation, 24-hour time of the real instant (a DST gap shows the hour it lands on).
    private static func closeTime(_ instant: Date, timeZone: TimeZone, locale: Locale) -> String {
        format(instant, "EEE HH:mm", timeZone: timeZone, locale: locale)
    }

    private static func format(_ date: Date, _ pattern: String, timeZone: TimeZone, locale: Locale) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = pattern
        return f.string(from: date)
    }
}
