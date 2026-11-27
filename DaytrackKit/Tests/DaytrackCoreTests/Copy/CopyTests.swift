import Foundation
import Testing
@testable import DaytrackCore

private let newYork = TimeZone(identifier: "America/New_York")!
private let posix = Locale(identifier: "en_US_POSIX")

private func at(_ day: String, _ hour: Int, _ minute: Int = 0) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = newYork
    let d = DayKey(day)!
    return cal.date(from: DateComponents(year: d.year, month: d.month, day: d.day, hour: hour, minute: minute))!
}

private func chip(lockHour: Int) -> String {
    let close = DayClosing.closeInstant(DayKey("2027-07-22")!, lockHour: lockHour, tz: newYork)
    return Copy.amendChip(closeInstant: close, timeZone: newYork, locale: posix)
}

private let mood = Tracker(name: "Mood", symbol: "face.smiling", type: .numeric, createdAt: DayKey("2027-07-01")!)
private let pain = Tracker(name: "Pain", symbol: "bandage", type: .ordinal, createdAt: DayKey("2027-07-01")!)

@Suite struct CopyTests {
    @Test func amendChipAtLockHour20() {
        #expect(chip(lockHour: 20) == "until Fri 20:00")
    }

    @Test func amendChipAtLockHour23() {
        #expect(chip(lockHour: 23) == "until Fri 23:00")
    }

    @Test func settingsLabelAtLockHour0SaysNoGraceDay() {
        #expect(Copy.settingsLockHour(0) == "00:00 · no grace day")
        #expect(Copy.settingsLockHour(20) == "20:00")
        #expect(Copy.settingsLockHour(7) == "07:00")
    }

    @Test func dotStripSeparatesSkipped() {
        #expect(Copy.dotStrip(RowCounts(written: 6, skipped: 2, blank: 1)) == "6 written, 2 skipped, 1 still blank")
    }

    @Test func valueLabelSaysNotWrittenYet_neverNothing() {
        let blank = Copy.valueLabel(mood, value: nil, labels: [])
        #expect(blank == "Mood, not written yet. Activate for choices")
        #expect(!blank.lowercased().contains("nothing"))
        #expect(Copy.valueLabel(mood, value: .skip, labels: []) == "Mood, skipped. Activate for choices")
        #expect(Copy.valueLabel(mood, value: .set(7), labels: []) == "Mood, 7. Activate for choices")
    }

    @Test func valueLabelUsesWordForOrdinal() {
        #expect(Copy.valueLabel(pain, value: .set(5), labels: pain.labels) == "Pain, Mild. Activate for choices")
        let older = ["None", "Some", "Light", "Medium", "Heavy"]
        #expect(Copy.valueLabel(pain, value: .set(5), labels: older) == "Pain, Light. Activate for choices")
    }

    @Test func padKeysNameTheTracker() {
        #expect(Copy.skipKey("Sleep") == "Skip Sleep")
        #expect(Copy.leaveBlankKey("Sleep") == "Leave Sleep blank")
    }

    @Test func skipRestUsesDayLabel() {
        let now = at("2027-07-23", 9)
        let today = Copy.dayLabel(for: DayKey("2027-07-23")!, now: now, timeZone: newYork)
        let yesterday = Copy.dayLabel(for: DayKey("2027-07-22")!, now: now, timeZone: newYork)
        #expect(today == "today")
        #expect(yesterday == "yesterday")
        #expect(Copy.dayLabel(for: DayKey("2027-07-21")!, now: now, timeZone: newYork) == nil)
        #expect(Copy.skipRest(dayLabel: today!) == "Skip the rest of today")
        #expect(Copy.skipRest(dayLabel: yesterday!) == "Skip the rest of yesterday")
    }

    @Test func noteFooterMatchesChipCloseTime() {
        let close = DayClosing.closeInstant(DayKey("2027-07-22")!, lockHour: 20, tz: newYork)
        let footer = Copy.noteFooter(closeInstant: close, timeZone: newYork, locale: posix)
        #expect(footer == "Editable until Fri 20:00, then it is written like the numbers.")
        #expect(footer.contains(chip(lockHour: 20)))
    }

    @Test func lastFullCopyFactLine() {
        let now = at("2027-07-23", 9)
        #expect(Copy.lastFullCopy(at("2027-07-12", 18), now: now, timeZone: newYork, locale: posix)
                == "Last full copy: 12 Jul (11 days ago)")
        #expect(Copy.lastFullCopy(at("2027-07-22", 23), now: now, timeZone: newYork, locale: posix)
                == "Last full copy: 22 Jul (1 day ago)")
        #expect(Copy.lastFullCopy(at("2027-07-23", 8), now: now, timeZone: newYork, locale: posix)
                == "Last full copy: 23 Jul (today)")
    }

    @Test func noCopySavedYetFactLine() {
        #expect(Copy.lastFullCopy(nil, now: at("2027-07-23", 9), timeZone: newYork, locale: posix) == "No copy saved yet")
    }

    @Test func noOutputContainsBannedWords() throws {
        // Split so the repo lint (which scans string literals) does not flag the pattern itself.
        let banned = try Regex(
            #"(?i)\b(log|logg"# + #"ed|entered|recorded|stre"# + #"ak)\b|23:"# + #"59|mid"# + #"night"#
        )
        let now = at("2027-07-23", 9)
        var outputs = [
            Copy.settingsLockHour(0), Copy.settingsLockHour(23),
            Copy.dotStrip(RowCounts(written: 1, skipped: 0, blank: 3)),
            Copy.valueLabel(mood, value: nil, labels: []),
            Copy.valueLabel(mood, value: .skip, labels: []),
            Copy.valueLabel(mood, value: .set(3), labels: []),
            Copy.valueLabel(pain, value: .set(10), labels: pain.labels),
            Copy.skipKey("Mood"), Copy.leaveBlankKey("Mood"),
            Copy.skipRest(dayLabel: "today"),
            Copy.dayLabel(for: DayKey("2027-07-22")!, now: now, timeZone: newYork)!,
            Copy.lastFullCopy(nil, now: now, timeZone: newYork, locale: posix),
            Copy.lastFullCopy(at("2027-07-12", 18), now: now, timeZone: newYork, locale: posix),
        ]
        for hour in [0, 20, 23] {
            let close = DayClosing.closeInstant(DayKey("2027-07-22")!, lockHour: hour, tz: newYork)
            outputs.append(Copy.amendChip(closeInstant: close, timeZone: newYork, locale: posix))
            outputs.append(Copy.noteFooter(closeInstant: close, timeZone: newYork, locale: posix))
        }
        for output in outputs {
            #expect(output.firstMatch(of: banned) == nil, "\(output)")
        }
    }
}
