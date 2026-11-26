# Daytrack: decision record for the 11 open product questions

This record reconciles 14 recommendations (Q1 to Q11, with Q7, Q10 and Q11 split) that separate agents wrote without seeing each other. Where they clashed I picked one answer, and I amended any answer that broke a HANDOFF §1 rule or a §6 honesty rule without saying so. Five decisions still need the owner's taste; the rest follow from rules already in HANDOFF.

## Decisions at a glance

| Q# | Decision (one line) | Needs owner? | Confidence |
|---|---|---|---|
| Q1 | A day is its calendar date. It stays "Today" until midnight and closes for good at the lock hour the next day. Lock hour 0 means no grace day | yes | medium |
| Q2 | No automatic backup and no endpoint. One prominent "Save a full copy" (JSON) plus a "Last full copy" fact line | no | high |
| Q3 | Nothing changes a closed day, restore included. Next-day writes and imported days are counted on the provenance sheet | no | high |
| Q4 | Tapping a value opens the choice pad (stops, Skip, Leave blank) in every mode. No single tap erases anything | yes | high |
| Q5 | A "written value" is a set value. Floors count per tracker, in the latest era inside the range. Skipped and blank are counted separately | no | high |
| Q6 | No wording corrections. Labels edit freely until a closed day holds a value; after that every change is a revision. Stop count is fixed | no | high |
| Q7a | Tabs are Today / History / Report / Settings, as HANDOFF says. Trackers moves to Settings and stays reachable from the board | no (confirm only) | high |
| Q7b | Compare can add its pair, with the lag, to the report draft. The pair is computed over the report's range | no | high |
| Q8 | Moving phones = save a full copy, then restore. The QR pairing flow is cut. Native config excludes the store from device transfer | no | high |
| Q9 | On iOS, install comes before day one, with a "Write in Safari for now" escape. Android and desktop keep install after day one | yes | high |
| Q10 | The reminder is an absolute local time (default 21:30), native only. Permission is asked only when the user taps an explicit button | no | high |
| Q10b | The PWA has no reminder, no notification actions and no icon badge. Manifest shortcuts stay | yes | high |
| Q11a | At most 8 active trackers. Archive is unlimited | no | medium |
| Q11b | Unpicked starters are a template catalog, never created as trackers. Trackers get createdAt and archivedRanges | no | high |

---

## Q1. Lock hour: deadline or day boundary

**Decision.** Option C.
- The date key is the local calendar date. Day D is "Today" from its midnight until the next midnight, then "yesterday".
- D closes for good at the first local instant at or after lockHour:00 on D+1. On a spring-forward day where HH:00 does not exist, that is the first instant after it.
- lockHour is 0 to 23. 0 means D closes at its own midnight, so there is no grace day and no Amend tab.
- Settings stores `closedThrough: DateOnly`. It only moves forward, so raising the lock hour, or travelling west, never reopens a closed day.
- Lowering the lock hour below the current time closes yesterday at once, after a one-line confirm.
- The §4 mid-drag deferral applies to both timed events: the relabel at midnight and the close at the lock hour.

**Why.** Rule 2 already lets D be edited until the lock hour on D+1. A "lock" on D's own evening therefore protects no data and can only show up as a false read-only state. Option B re-dates evening entries, which breaks §9 ("never re-dated") and the clinician's dates.

**Options considered.**
- A. Same-day deadline: produces a fake read-only hour and false "locks" copy.
- B. Lock hour as the day boundary: misdates evening entries.
- C. Calendar day with one close instant: chosen.

**What changes.**
- §1 rule 2: see "Rule changes".
- §2 Settings: add `{ lockHour, closedThrough, reminderAt }`.
- §2 DayEntry: see Q3 for the field set (this replaces Q1's "derive amended from lastWrittenAt").
- §3 Amend row: chip reads "until {weekday} {HH}:00". Amend is hidden when lockHour = 0.
- §3 Today row: no same-day lock event.
- §9: day-turning and time-zone bullets use the two events, midnight relabel and lock-hour close.
- Settings label: "Yesterday stays open until", with "00:00 · no grace day" at 0.
- One derived string replaces every hard-coded lock string: "LOCKS 23:00", "23:59", "until midnight", `lockHour+':59'` (:2615, :2321), and the widget label in §10 ("three still to write, Mon open until Tue 23:00").
- Prototype `lockDay()`: stop copying vals and stop clearing today at the lock hour.
- Tests: lock hour 0, 20 and 23; a DST day; raising and lowering the lock hour while yesterday is open; a time-zone crossing.

**Amendments.**
1. Rule 2 wording is merged with Q3's version into one sentence.
2. The notification channel "Before the day locks" (:1349, :1484, :2764) must be renamed, because no same-day lock exists any more. Proposed name: "Daily reminder". The reminder screen headline changes the same way.
3. With lockHour 0, the missed-reminder strip says yesterday is closed and offers no Amend action.

## Q2. Backup beyond manual export

**Decision.** Option A.
- Cut the automatic backup, the custom endpoint and the backup-owner model (bkOwner, the twin frame, the §9 "Two devices" case).
- Add one primary "Save a full copy" action. It writes the complete JSON (trackers, revisions, archive ranges, entries, notes) and hands it to the OS share or save sheet.
- Add the fact line "Last full copy: 12 Jul (11 days ago)" or "No copy saved yet", from a device-only `lastFullCopyAt`. It is never a nag, badge or notification.
- CSV is documented as lossy.
- The PWA calls `navigator.storage.persist()` on the first write.

**Why.** Rule 1 and §8 ("a cloud copy makes every privacy claim false"; "no persistent directory grant") already forbid both features. A PWA cannot write to a folder in the background at all.

**Options considered.**
- A. Manual full copy only: chosen.
- B. Automatic folder backup: native only, breaks rule 1 and the picker rule.
- C. User-supplied HTTPS endpoint: a network call, breaks rule 1 outright.

**What changes.**
- §1 rule 1 gains one sentence (see "Rule changes").
- §2: add `lastFullCopyAt?` (device-only, not exported).
- §3 Export row: "Save a full copy (JSON)" plus "Other formats".
- §3 Restore row: drop the collision and ownership flow.
- §9: replace "Two devices writing one backup file" with "Restoring a copy from a phone that kept writing" (per-day diff, second confirmation, merge rule from Q3).
- Prototype: remove the export settings blocks (~:733-770) and the handoff copy (:3942-3954).
- Onboarding (:1821-1826): "Keep a copy whenever · One tap saves a file you keep. Daytrack never sees where it goes."
- Erase (:3311, :1774, :1782): "Daytrack keeps no other copy. Files you saved yourself are not touched; Daytrack cannot see them."
- Use one file name, `daytrack-YYYY-MM-DD.json`.
- Re-audit every string containing "backup".

**Amendments.**
1. Q2 said the Offline screen is "unchanged and now true". That is false for the PWA. The No-connection state lists "export (the file is written locally; sending it on can wait)", but on an iOS PWA the share sheet or download *is* the write. PWA copy becomes "export (saved through the share sheet; Daytrack uploads nothing)". The §8 bullet "Export writes locally first" becomes native-only.
2. Erase also clears Settings, `closedThrough`, `lastFullCopyAt` and the ReportDraft (Q7b).

**Verified.** File sharing through `navigator.share({files})` is listed as supported in iOS Safari 14+ (caniuse), with early quirks. Use `canShare` and test on a device.

## Q3. Changes after the lock, and provenance

**Decision.** Option A.
- A day closes once (Q1). After that nothing on this phone changes it, restore included.
- Restore brings in only days this phone does not have.
- When a day exists on both sides and differs, this phone's version is kept and the dates are listed ("3 days differ, kept as written on this phone"). There is no "Let the file win".
- An imported day still inside its window stays editable like any other, and its origin stays `'import'`.
- Import never changes how a day already on this phone is read. If reconciling wording would require that, the file's tracker comes in as a separate archived tracker.
- DayEntry fields:
  - `firstWrittenAt` and `lastWrittenAt` (these replace `writtenAt`);
  - `tzOffsetAtWrite`;
  - `writtenNextDay: boolean`, set at write time on the local clock. Any write counts, including a note, a skip or a clear;
  - `origin: 'device' | 'import'`;
  - `importedAt?`.

**Why.** Rule 2 already says "then never again". Day-level flags give the clinician the counts they need without a per-value log.

**Options considered.**
- A. One final close, with counts: chosen.
- B. Allow and audit post-lock changes: rule 2 becomes false.
- C. Per-value edit log: too heavy, and proves no more than A.

**What changes.**
- §1 rule 2: see "Rule changes".
- §2: the DayEntry fields above.
- §3 Restore row and §9: per-day diff, absent days in, differing days kept here.
- §7 provenance sentence becomes: *"Patient-entered on the day or, at the latest, on the following day, and not reconstructed at the visit. Once a day closes it cannot be edited. In this range, {x} of {n} days were written or changed on the following day, and {y} days were brought in from an export file, carrying times recorded elsewhere that this copy cannot verify."* Keep the scale, missing-day and revision sentences.
- Export JSON carries the new fields. On import, origin is forced to `'import'`.
- Prototype: remove "Let the file win" (:1196-1210, :3910) and "Correct the wording" (:3136-3140). Print x and y on the provenance sheet (:2050).
- Screens: 14, plus the restore diff frame.

**Amendments.**
1. A stored `writtenNextDay` flag replaces Q1's "derive from lastWrittenAt". Deriving it from timestamps after a time-zone change is ambiguous.
2. The sheet no longer prints "by {lockHour}". The lock hour can change inside a range, so the printed hour could be false. The x count states the fact instead.
3. After a phone move (Q8), every earlier day is `'import'`, so y = n for that history. That is true and stays.

## Q4. Tapping a value; clearing to blank

**Decision.** Option B.
- Tapping the value opens the choice pad in drag, stepper and large modes alike.
- The pad has the stops, "Skip {tracker}", and, when the row is set or skipped, "Leave {tracker} blank". Each key commits and closes on the same frame.
- Clearing is allowed only until the day closes, and counts as a write (Q3).
- The day-level action is renamed "Skip the rest of {dayLabel}". It writes `'skip'` only into blanks.

**Why.** Rule 3, plus "never write a value the user did not enter", rule out a one-tap toggle that can silently lose a value. The current toggle already merges states (review High 3).

**Options considered.**
- A. Tap toggles skipped: one tap, but destroys data and is undiscoverable.
- B. Tap opens the pad: chosen.
- C. Long-press only: undiscoverable and poor for tremor.

**What changes.**
- §3 slider row: the "Tapping a value directly toggles skipped" line goes. The Stepper pad spec becomes the general pad spec.
- §10: the value box is a button, "{tracker}, {value | skipped | not written yet}. Activate for choices".
- Copy deck: "Skip {tracker}", "Leave {tracker} blank", "Skip the rest of {dayLabel}". The last one also replaces "Nothing to log today" on the native notification action, the `go=skip` shortcut and the widget.
- Prototype: `onValTap` (:2544-2548), `onPadSkip` (:2504), a new clear handler, `aValLabel` (:2531).
- Day-one hint (:2809/2811): drop it, or make it mode-independent.
- Screens 01, 03 and 04 get a pad frame.
- No data-model change.

## Q5. What a "written day" is

**Decision.** Option B.
- A written value is a set value.
- The report prints a tracker's chart and mean only with at least 14 written values in range, counted in the latest era inside the range. Below that it prints n, the reason and the remainder.
- The builder can generate when at least one selected tracker passes.
- Pairs need 12 days where both trackers are set, each tracker inside its latest era in the range.
- Dot strip and aria: "n written, k skipped, b still blank". The widget shows blanks remaining.
- Day-level labels use "days with anything written" and show skipped-only and blank days as separate counts.
- Blank counts are clipped to each tracker's active span (Q11b).

**Why.** §6 excludes skips and blanks from means, so the floors that protect means must count only set values. Rule 3 forbids the current dot strip, which merges skipped into written.

**Options considered.**
- A. Any value counts the day: passes the floor with 3 values.
- B. Per-tracker set values: chosen.
- C. Complete days only: streak-like, against rule 5.

**What changes.**
- §6: report floor per tracker, era-scoped. Pair floor wording made explicit.
- §3: Today, Report builder and widget rows.
- §5: glossary line for written value, skipped, blank and "day with anything written".
- Prototype: dotsLabel (:2797), the header (:3517-3522), the floor (:3473-3474), the builder (:3495-3498).
- Screens 01, 09, 13 and 28.

**Amendment.** Q5 said "current era". That is wrong for a range that ends in the past. §6 requires the era after the most recent revision *inside the range*, so the floor uses that.

## Q6. Wording corrections; stop count

**Decision.** Option A.
- There is no correction mode.
- Labels and numeric anchors edit freely until a closed day holds a value (set or skipped) for that tracker. After that, every wording change creates a ScaleRevision effective from today.
- The stop count follows from the type and is immutable with it.
- A different scale means archiving the tracker and creating a new one.
- On import, a stop-count mismatch with the same id comes in as a separate archived tracker.

**Why.** Rule 7 already demands a boundary. Corrections are the only path that re-reads closed days (Q3).

**Options considered.**
- A. No corrections; fixed stops: chosen.
- B. Recorded corrections: re-reads closed days and needs a rule-7 change.
- C. Stop-count revisions with remapping: the §8 "worst bug" path.

**What changes.**
- §1 rules 6 and 7: see "Rule changes".
- §2: ScaleRevision gains `trackerId`, and `previousLabels.length === stops` is validated. Tracker gains `anchors?: [string, string]` for numeric endpoints (already in the prototype at :2302).
- §8 older-file import uses the absolute `effectiveFrom` carried in the file.
- Prototype edit screen (:3136-3207): delete the "fix" branch; show the boundary consequence only once the tracker has a closed day; extend `typeLockNote` to cover stops.
- Copy: "These words can change freely until the first day closes; after that, a change starts new wording from today."
- Screens: the tracker edit labels panel, and 21.

**Amendments.**
1. "Replace tracker" does not exist in the prototype (grep finds nothing), so no new button is added. The path is the existing archive plus create.
2. "First day closes" is made precise: a closed day holding a value for *this* tracker.

## Q7a. Report tab and the home of Trackers

**Decision.** Option A, as HANDOFF §3 already states.
- Tabs are Today / History / Report / Settings.
- Trackers is the first row of Settings and stays reachable from the board (:108, :176).
- History gets a "Report this range" header action (generalise `onRgUse` at :3617).
- The Report tab's thin state reuses repThin copy: the count, the reason and the remainder. No ring or bar (rule 5).

**Why.** The spec chose this; the prototype is the side that drifted.

**Options considered.**
- A. Follow HANDOFF: chosen.
- B. Keep the prototype's Trackers tab: buries the core output.
- C. Five tabs: crowded in large-text mode.

**What changes.**
- Tab bar :1970-1985 uses `nav.report` (:2682).
- Back paths :508 and :548 return to their opener.
- boardEmpty "Bring one back" goes to Settings › Trackers.
- HANDOFF §3 Manage and Report builder rows note their entry points.
- Re-export screens 01, 05 and 10. Restore screen 15.

**Amendment.** needsOwner changed to "no (confirm only)". HANDOFF already decided this. Ask only if the prototype's tab bar was a deliberate later change.

## Q7b. Compare adds its pair to the report

**Decision.** Option A.
- Compare gets "Add to report · computed over the report's range ({range}), not this one".
- It writes `{a, b, lag}` into a persisted local ReportDraft, deduplicated on (a, b, lag). An already-added pair reads "In the report".
- The pair sheet uses the report range, the 12-day both-set floor, era windowing and the "chosen after seeing the data" line, and prints its lag.

**Why.** It keeps one range per report. Carrying the lag prevents a silent same-day misreport.

**Options considered.**
- A. Add, computed over the report range: chosen.
- B. Builder only: loses the lag.
- C. Snapshot Compare's range: mixed ranges in one report.

**What changes.**
- §2: `ReportDraft { range; trackers; sections; pairs: {a, b, lag: 0|1}[] }`. It is device-local, not exported, and cleared by Erase.
- repPairs becomes objects (:2300, :2637, :3627, :3638). `pairStats` (:2442) takes the lag from the pair.
- Compare shows its own range (review Low-4).
- §3 Compare row and §7 pair sheets state the lag.

## Q8. Moving to a new phone

**Decision.** Option A.
- One "Move to a new phone" row under Settings › Data opens a three-step explainer: Save a full copy; send it however you like; on the new phone, "I already have Daytrack days", then the picker, then the restore diff.
- The explainer says the old phone keeps its days until erased, and that days written there after the copy are not carried.
- The QR / "Take over" path is cut (:724-727, :760-770, :3986, the `src==='phone'` branches at :2614 and :3907-3908, restorePhone).
- Native Android: `allowBackup="false"` plus `dataExtractionRules` excluding the store from `<cloud-backup>` and `<device-transfer>`.
- Native iOS: the store is marked `isExcludedFromBackup`.

**Why.** The receiving side (Restore) already exists. Pairing would need a rule-1 rewording and many new failure states to reach the same diff screen.

**Options considered.**
- A. Export plus restore: chosen.
- B. QR + WebRTC pairing: a network transfer, many new states.
- C. OS migration tools: not available to the PWA, and makes the §8 promise false.

**What changes.** §8 native backup paragraph; §3 Onboarding row (always goes through the picker, review Medium 19); the new Data row and explainer copy.

## Q9. iOS install timing

**Decision.** Option A, applied to any iOS browser tab (all are WebKit with separate storage), not only Safari.
- Onboarding opens with an install step: "On iPhone, Daytrack keeps your days only once it is on the home screen. A browser tab has separate storage that the home-screen app cannot see."
- The step offers "Write in Safari for now". In tab mode a quiet strip reads "These days live in this browser only", with Install and Save a full copy.
- The hand-over is the Q8 path. No migration code is needed.
- Android and desktop keep install after day one.
- On iOS, the day-one-written screen offers "Save a full copy", not install.

**Why.** Separate storage guarantees that an installed app launched after day one opens empty (review High 7).

**Options considered.**
- A. Install before day one on iOS: chosen.
- B. After day one with an export hand-over: about 6 steps, fails silently.
- C. Hand-over carried in the start URL: leaks the data into history.

**What changes.**
- §3 surfaces table ("Getting it") and the Install/Nudge row; §8 install bullet.
- Screen 11 gets the pre-step.
- Install copy (:1232-1234): "it starts with its own, empty storage; days written in the browser stay there". Add the §8 sentence that deleting the icon takes the record.
- Detection: `navigator.standalone`, the `display-mode: standalone` media query, and an iOS user-agent check.

**Amendments.**
1. Q9 said the day-one screen offers "Export as a backup". It is "Save a full copy", the Q2 vocabulary.
2. The persistent tab-mode strip is a storage fact, not a copy-age nag, so it does not conflict with Q2.
3. Unverified: the exact menu path in non-Safari iOS browsers. Instruction copy may need per-browser variants.

## Q10. Reminder timing and permission (native)

**Decision.** Option B.
- `reminderAt: 'HH:MM' | null`, default 21:30. It fires only if today has blanks and is cancelled when the board has none.
- Permission is never asked at launch. The prompt appears only after a tap on "Remind me at 21:30" on the day-one-written screen, or when the reminder is turned on in Settings. It is asked once. After a refusal, Settings shows "Notifications are off for Daytrack in system settings", with no re-prompt.
- Android: `POST_NOTIFICATIONS` is asked on the same tap. Use an inexact window alarm with no `SCHEDULE_EXACT_ALARM`; copy says "around 21:30". Reschedule on time-zone change, time set and boot.
- iOS: individual non-repeating calendar triggers for the coming days, refilled on app open. Copy: "scheduled for 21:30; delivery can still move it".

**Why.** Under Q1 there is no same-day lock to offset from, and the UI already shows clock-time chips.

**Options considered.**
- A. Offset before the lock: no anchor under Q1.
- B. Absolute clock time: chosen.
- C. Both: extra settings and tests for no gain.

**What changes.**
- §8 "lock hour minus offset" becomes "the user's chosen local time".
- Drop the `SCHEDULE_EXACT_ALARM` sentence in §3, §8 and screen 26.
- Reminder eyebrow (:1348, :1483) becomes "AFTER DAY ONE".
- Day-one copy (:2811) becomes the button plus a "No reminder" link, with no "asks again" promise.
- Screens 25, 26 and 27 show the chosen time.

**Amendments.**
1. Under Q10b this is native-only. The PWA permission and user-gesture reasoning is moot.
2. iOS keeps at most 64 pending local notifications (from memory, not verified), so schedule about 14 days ahead. If the app is not opened for that long, reminders stop. Settings copy states this plainly; no re-fire.

**Verified.** Android 14 denies `SCHEDULE_EXACT_ALARM` by default to most new installs targeting 13+ (developer.android.com, Android 14 behaviour changes). This supports dropping exact alarms.

**Unverified.** iOS floating-time triggers after a time-zone change; Android's "no dialog after two denials".

## Q10b. Can the PWA have reminders at all

**Decision.** Option A.
- The PWA ships with no scheduled reminder, no notification actions, no missed-reminder strip and no icon badge.
- Install and nudge copy: "A home-screen web app cannot set its own reminder without a server, and Daytrack has none. The native app can."
- Manifest shortcuts (`?go=today|yesterday|skip|week`) stay. They need no notifications.

**Why.** Rule 1 forbids the server that Web Push needs. Notification Triggers never launched in Chrome: the origin trial is complete and launch is "Not started" (developer.chrome.com). Periodic Background Sync gives no clock time.

**Options considered.**
- A. Native-only reminders: chosen.
- B. Web Push from an owned server: breaks rule 1.
- C. Periodic Background Sync on Android: no time can be stated honestly.

**What changes.**
- §3 surfaces table: PWA cells for reminder permission, reminder timing, notification actions and home screen.
- §8: the PWA reminder paragraphs and the "permission only after install" bullet. Screens 16, 17 and 18 and the PWA nudge frames are cut or replaced by one explanatory panel.
- The Reminder timing screen keeps only the native position.

**Amendments.**
1. The PWA icon badge is cut too (this settles Q10b's open item). Verified: on iOS the badge is displayed only once notification permission is granted (WebKit, iOS 16.4 post), and that permission would exist for nothing else. Chrome Android does not support `setAppBadge` (Chrome docs, caniuse). A badge updated only while the app runs would show a stale count after the day turns, which is a false statement on the home screen.
2. Q10b's option text called the long-press actions "cut". Only notification actions are cut; manifest shortcuts remain.

## Q11a. Cap on active trackers

**Decision.** Option A.
- At most 8 active trackers; archive is unlimited.
- "+" and "Bring one back" are disabled at 8 with "Eight fit on one board. Archive one to make room." The disabled control announces that reason.
- Onboarding refuses a 9th with the same line.
- A restore that would exceed 8 brings the extras in archived; the diff says so and lets the user choose which 8 are on the board.
- Large-text mode keeps scrolling, as it already does.

**Why.** "Eight things, one screen" and the "no scrolling target" spec.

**Options considered.**
- A. Hard cap of 8: chosen.
- B. Soft cap with scrolling: breaks the board spec.
- C. Cap from screen height: unpredictable.

**What changes.** §1 gains rule 8; §3 Manage/Edit and Onboarding rows; picker logic at :3242-3247.

**Unverified.** That 8 default rows fit a 390×844 frame. Measure screen 01 before shipping the number.

## Q11b. Unpicked starter trackers

**Decision.** Option A.
- Only picked starters are created. The rest form a read-only catalog, offered on the create screen as "Start from a common one".
- Tracker gains `createdAt: DateOnly` and `archivedRanges: {from; to?}[]`.
- Blank counts, floors and grids are clipped to the tracker's active span.

**Why.** A tracker the user never chose cannot have blank days (rule 3). Erase must state the real count.

**Options considered.**
- A. Template catalog, never created: chosen.
- B. Archive them, as the prototype does: creates phantom trackers and false blanks.

**What changes.**
- §2 Tracker fields; §2 Defaults line ("a starter catalog, not trackers").
- Prototype `onStart` (:3405): order = picked, arch = [].
- Erase (:3305-3312) and the Archive list need no further change.

**Amendments.**
1. The `archived: boolean` field is derived from the last range having no `to`. It is not stored separately, so there is no second source of truth.
2. Trackers from older files that lack `createdAt` take the date of their earliest value.

---

## Rule changes

1. **Rule 1** keeps its text and adds: *"Copies exist only when the user saves one; Daytrack never writes a copy on its own. The home-screen web app has no reminders, because a reminder would need a server."*
2. **Rule 2** is replaced with: *"Each day is its local calendar date. It can be written from its midnight until the lock hour (default 23:00, settable 0–23) on the following day, then it closes and nothing changes it again, restore included. Lock hour 0 means no grace day. A closed day never reopens, even if the lock hour is raised or the clock moves back."*
3. **Rule 6** becomes: *"A tracker's type, and with it its number of stops, is immutable after creation. Renaming and re-iconing are free."*
4. **Rule 7** adds: *"There is no correction mode. Words edit freely only until a closed day holds a value for the tracker; after that, every change is a revision."*
5. **New rule 8:** *"At most eight trackers are on the board at once. Archive is unlimited."*

These are non-§1 lines that are overridden; flag them in HANDOFF:
- §3 "Tapping a value directly toggles skipped" (Q4);
- §3 and §8 "install only after day one" (Q9, iOS);
- §6 report floor (Q5);
- §7 provenance sentence (Q3);
- §8 "lock hour minus offset" and the exact-alarm lines (Q10);
- §8 PWA reminder and badge lines (Q10b);
- §9 "Two devices" (Q2).

## Still the owner's call

1. **Q1:** Drop the nightly "it locks tonight" ritual for "yesterday stays open until 23:00" (recommended), *or* keep a same-day lock and accept a read-only hour that protects nothing?
2. **Q10b:** Ship the PWA with no reminder or badge (recommended), *or* rewrite rule 1 and every privacy string to allow a push server?
3. **Q9:** On iOS, ask for install before day one (recommended), *or* keep "value before commitment" and accept a manual export hand-over that fails silently if skipped?
4. **Q4:** Make skip two taps through the pad so no tap can erase (recommended), *or* keep one-tap skip and accept that a mis-tap can lose a value?

Q7a needs confirmation only, not a taste call.

---

Sources for the claims I checked: [WebKit: Web Push for Web Apps on iOS and iPadOS](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/), [Android 14: schedule exact alarms denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms), [Chrome: Notification Triggers API](https://developer.chrome.com/docs/web-platform/notification-triggers), [Chrome: Badging API](https://developer.chrome.com/docs/capabilities/web-apis/badging-api), [caniuse: setAppBadge](https://caniuse.com/mdn-api_navigator_setappbadge), [caniuse: navigator.share files](https://caniuse.com/mdn-api_navigator_share_data_files_parameter).

Not checked: the iOS 64-pending-notification limit, iOS floating-time triggers, the 8-row fit on screen 01, and the EU home-screen web app status.
## Owner decisions

- **Q1 approved (2026-11-26):** each day stays open until the lock hour the next day. There is no same-day lock.
- **Platform (2026-11-26):** a native iOS app in SwiftUI, built in Xcode on the owner's Mac. There is no PWA. This makes Q9 (iOS install before day one) and Q10b (PWA reminders) moot: reminders are local `UNCalendarNotificationTrigger`s, and the widget uses WidgetKit.
- **Q4 (2026-11-26):** take the recommendation. Tapping a value opens the choice pad (the stops, Skip, Leave blank) in every mode. No single tap erases a value.
- **Q7a:** confirmed: Today / History / Report / Settings, with Trackers under Settings.
- **Visual (2026-11-26):** the app is fully Liquid Glass. Rows, the choice pad, strips and chips are glass (`GlassEffectContainer`), over a warm ambient background instead of flat black, so the glass has something to refract. This overrides the flat-dark look in HANDOFF §4. Legibility must still pass with Reduce Transparency and Increase Contrast.
- **G2 (2026-11-26):** the owner's iPhone is an iPhone 17 Pro on iOS 27.2.1. This confirms [O7]: the deployment target stays iOS 26.0, which the phone exceeds.
