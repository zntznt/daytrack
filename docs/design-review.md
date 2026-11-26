# Daytrack: user-flow design review

## Verdict

The core loop holds up: pick a few sliders, write the day on one board, and get an honest report for a clinician. The product rules in HANDOFF are clear and principled. The prototype breaks them in a few load-bearing places, though, and they cluster around three themes.

1. **Time.** The lock, the grace day and the day turn are never pinned down. The app states the deadline as 23:00, 23:59 and midnight, sometimes on the same screen.
2. **Privacy and data lifecycle.** An automatic cloud backup sits under a "NO CLOUD" headline, and erase, install and restore all leave copies or gaps behind.
3. **Statistics honesty.** Averages cross wording revisions, date ranges are off by one, and skipped and blank values get merged.

None of this needs a redesign of the flows. It needs a few product decisions (listed at the end), then a pass that derives every string and count from one source.

## User-flow map

- **First run:** Onboarding -> Pick first sliders -> Today board (day one) -> Day one written -> Install prompt -> Home-screen app [MISSING: carrying day one into the installed app on iOS] -> Reminder permission [trigger stated 3 ways]
- **Daily loop:** Today board -> drag / stepper / large text -> tap value to skip [tap clears instead] -> Lock at lock hour -> [MISSING: what happens from lock to midnight] -> Day turns
- **Grace day:** Today -> Amend strip [hidden by the update strip] -> Amend board (yesterday) -> locks at today's lock hour [copy says midnight]
- **Reminders:** Settings -> Nudge -> time [absolute time, but spec says offset] -> Notification ("Nothing to log today" / open) -> Missed-reminder strip [MISSING: trigger] -> "Why it was held" -> back goes to Settings [wrong]
- **Returning after a lapse:** Lapse strip ("no backlog") vs missed strip ("Amend Wednesday") [MISSING: which one wins]
- **Read side:** History (30d/90d/1y) -> Tracker detail -> Compare / By weekday / Day detail -> back always goes to History [wrong]; History -> This week / Month -> Day
- **Report:** Settings -> Data -> Report builder [MISSING: a Report tab or a link from History or Compare] -> Summary / Provenance / Table / Pairs sheets [pair-sheet screenshot missing]
- **Edit tracker:** Trackers -> Edit -> Labels -> "Correct" (default) vs "New wording" -> Delete
- **Backup and restore:** Data -> Automatic backup [MISSING: spec, folder pick, on/off, failure, PWA-unsupported] -> File picker -> Open -> Restore diff [MISSING: wiring to the wrong-file and old-file screens]; Onboarding "I already have days" -> Restore [skips the picker]
- **New phone:** Old phone QR -> [MISSING: scanner, pairing, failure states] -> Restore
- **Erase:** Settings -> Erase -> Erased -> Start again [backup file not handled]
- **Offline:** Settings -> Works with no signal [MISSING: where the first-open caching and no-connection states appear]

## Findings

### High

1. **The lock time and grace-day deadline appear as 23:00, 23:59 and midnight**
   - **Flow:** daily loop, amend yesterday, reminders, widget, report.
   - **Problem:** Rule 2 says the lock is the lock hour (default 23:00) and that yesterday stays editable until today's lock hour. The code builds the lock as lockHour:59. Hard-coded copy then says 23:00 in some places and "midnight" in others. With a lock hour of 20, the amend copy promises about 4 more hours than the user really has.
   - **Evidence:**
     - The lock string and countdown: Daytrack.dc.html:2615 (`lockStr=lockHour+':59'`) and :2321.
     - Notification: "locks at 23:59" next to "It locks at midnight" (:1379, :1461, :1520; 27-native-reminder.png).
     - Widget hard-codes "LOCKS 23:00" (:1423).
     - Missed strip says "until 23:00 tonight" (:120).
     - Amend copy says "until midnight" (:130, :2837, :2839, :2935, :3282, :3889, :2824).
     - Report prints 23:59 (:2050).
     - HANDOFF:31 says 23:00; HANDOFF:142 says midnight.
   - **Fix:** Choose one canonical lock instant. Derive every chip, strip, notification, widget face and label, amend string and report line from the lock-hour setting. Add a test with a lock hour other than 23.

2. **The lock is not separated from the day turn**
   - **Flow:** day lock, data model.
   - **Problem:** At lock time, lockDay() moves today's values into "yesterday", clears today and switches to the amend tab, all on the same calendar date. With a lock hour below 23, the user gets an empty "today" board until midnight, and its writes collide with the day that just locked. Lock hour 0 is ambiguous.
   - **Evidence:** :2336-2342 and :2272 (lock hour min 0, max 23); HANDOFF:59 (DayEntry keyed by local date); HANDOFF:396.
   - **Fix:** Decide one of two models and design its state:
     - The lock hour is the day boundary, so writes after it belong to the next day.
     - The lock is a deadline, so today becomes read-only until midnight.

     Then constrain or explain lock hour 0.

3. **Tapping a written value erases it to blank instead of skipping it**
   - **Flow:** Today board in drag and large modes.
   - **Problem:** onValTap deletes any value that is set; only a blank becomes "skip". One tap, or a slightly off drag onto the number, silently destroys data with no undo. It also merges the blank and skipped states that rule 3 protects. The aria label ("activate to skip today") describes something else.
   - **Evidence:** :2544-2548 and :2531; HANDOFF:32, :50 and :172.
   - **Fix:** Define the tap state machine as set -> skipped (keeping the prior value) -> set. Make the code and the label agree. If clearing to blank is needed, give it an explicit control.

4. **The provenance sheet overstates contemporaneity to clinicians**
   - **Flow:** Amend yesterday or missed reminder -> printed provenance sheet.
   - **Problem:** The sheet says entries were made "once daily, on the day itself", "lock at 23:59" and "cannot be edited after". The grace day, the "Amend Wednesday" button, Restore with "file wins" and "Correct the wording" all make that false. DayEntry has a single writtenAt and no amended flag, so the sheet has nothing to disclose.
   - **Evidence:** :2050, :122 and :3322; HANDOFF:31, :58-64 and :309; 14-report-sheet-provenance.png.
   - **Fix:** Reword to "written on the day or the next, before its lock hour". Store first and last writtenAt (or an amended marker) and print the number of amended days.

5. **An automatic cloud backup and a custom endpoint contradict "local only / NO CLOUD"**
   - **Flow:** First run -> Settings -> Export & backup.
   - **Problems:**
     - Onboarding shows "NO ACCOUNT · NO CLOUD" directly above "pick iCloud Drive or Google Drive".
     - The Export screen has an AUTOMATIC BACKUP (switched on) and a "YOUR OWN ENDPOINT https://… Test" row.
     - Rule 1 says no network calls.
     - §8 says a cloud copy makes every privacy claim false and forbids persistent directory grants.
     - The Offline screen says the update check is the only network use.
     - A PWA on iOS cannot write a Files folder in the background, and HANDOFF never specifies the feature.
   - **Evidence:** :1820-1826, :733-760, :3400; HANDOFF:30, :339, :356, :371; 11-first-run.png; 22-offline-stored.png.
   - **Fix:** Either drop the backup and the endpoint, or make backup an opt-in, user-started flow. If it stays, rewrite rule 1 and every privacy string, and design the folder pick, on/off, failure and unsupported states.

6. **Erase leaves the backup file behind while saying no copy exists**
   - **Flow:** Settings -> Erase -> Erased -> Start again.
   - **Problem:** The copy says "there is no copy to fall back on" and "no copy anywhere else". Meanwhile daytrack-latest.json survives in the cloud. After "Start again", the still-running backup can overwrite it with an almost empty record, destroying the last copy.
   - **Evidence:** :3311, :1774 and :1782; onEraseDo :3315-3320 never touches the backup.
   - **Fix:** Erase names the backup file and offers to delete or keep it. Automatic backup stays paused after an erase until the user turns it back on.

7. **On iOS, day one is missing after Add to Home Screen**
   - **Flow:** Safari first run -> day one -> install -> open the home-screen app.
   - **Problem:** The install prompt only appears after day one is written, so that day lives in Safari's storage. An installed iOS web app gets separate storage and opens to an empty onboarding. The install copy ("keeps its own storage") implies the opposite. The iOS behaviour is platform knowledge and could not be verified from these files.
   - **Evidence:** HANDOFF:127, :161 and :322; :1232-1234.
   - **Fix:** Design a hand-over: export before install, then "I already have days" on first open. Alternatively, on iOS show the install prompt before day one. Say plainly that the installed app starts empty.

8. **"Correct the wording" rewrites every past day, and it is the default**
   - **Flow:** Trackers -> Edit -> Labels.
   - **Problem:** Rule 7 and §6 require a revision boundary for any wording change. The default option ("Applies to all N days") records none and changes the meaning of locked days. The same panel then says "A wording change never rewrites a day".
   - **Evidence:** :3136 and :3140 (`scaleMode` defaults to 'fix'), :3142, :3156 and :3207; HANDOFF:36, :298 and :309.
   - **Fix:** Make "Start new wording from today" the default. If corrections stay, record them (for example a revision with kind 'correction') and show them in wording history and on the provenance sheet.

9. **History rows, Compare and the weekday panel average across a wording-revision boundary**
   - **Flow:** History list; Tracker detail -> Compare.
   - **Problem:** §6 says no statistic may span two wordings. History rows use H[id].slice(-R) with no era cut. At 90d, Anxiety (revised 62 days ago) mixes both wordings, while the header above it shows the era-windowed mean, so one screen shows two averages. Compare's pairStats has no era logic. History and detail charts draw no boundary line.
   - **Evidence:** :2572, :3063-3066, :2661 and :2442-2449; markup :376-383 vs HANDOFF:298. Only the printed pair sheet windows the data (:3652, :2158).
   - **Fix:** Route every statistic through one era-windowing helper. Show the reduced n and draw a boundary line on every chart whose range crosses a revision.

### Medium

**Report and statistics**

1. **The printed date range is one day later than the data.**
   - **Flow:** Report sheets.
   - **Problem:** The label reads 25 Apr – 23 Jul (ending today), but the data covers 24 Apr – 22 Jul (ending yesterday). Custom ranges shift by one as well.
   - **Evidence:** :2631, :2635, :2368, :3574; screens 13 and 14.
   - **Fix:** Use one convention (ranges end at the last locked day) and derive both label and slice from absolute dates.

2. **The pair sheet prints the wrong revision date for custom ranges.**
   - **Flow:** Report -> custom range -> Pair sheet.
   - **Problem:** dLabel is called with a window-relative offset, so the chart label and the caption print two different dates for one boundary. This is exactly the bug HANDOFF §6 warns about.
   - **Evidence:** :3649-3651, :3683-3684 vs :3689.
   - **Fix:** Store and format boundaries as absolute dates. Convert to offsets only for x-position.

3. **The builder count and the printed count differ for a revised tracker.**
   - **Flow:** Report builder -> Summary.
   - **Problem:** The builder shows Anxiety "82 days", while the sheet prints 57/62 with no mention of the revision.
   - **Evidence:** screens 09 vs 13; :3495-3498 vs :3549-3552.
   - **Fix:** Show the era count and a revision marker in the builder.

4. **The summary header says "90 written · 0 blank" while rows show blanks.**
   - **Flow:** Summary sheet.
   - **Problem:** The header counts a day if any tracker has a value, and it counts all trackers rather than the selected ones. The 14-day floor uses the same "any one tracker" rule.
   - **Evidence:** :3517-3522, :3473-3474; screen 13.
   - **Fix:** Label it "days with anything written". Count only the selected trackers. Warn when a selected tracker has fewer than 14 values.

5. **Binary and ordinal averages are shown three different ways.**
   - **Flow:** History vs This week vs Summary.
   - **Problem:** Meds shows "Yes" (a rounded 0/1 mean, so 51% reads as Yes) on History, "2 / 4" on This week and "67/84" on the sheet. Ordinal means round to a single word with no n.
   - **Evidence:** :3065; screens 05, 07 and 13.
   - **Fix:** Use k/n for binary everywhere, and a distribution or median with n for ordinal.

6. **The week grid shows older skips as blanks, with no legend.**
   - **Flow:** History -> This week / Last week.
   - **Problem:** For days 2 or more back, the view reads H[id], where skips are stored as null. The skip flags live in _sk, which the view never reads.
   - **Evidence:** :3805-3809, :3821, :2361-2362; screen 07.
   - **Fix:** Read the skip flag for every past day and add a legend for "·" and "–".

7. **Record age says 128 days, but the 1y chip shows and the data spans 365.**
   - **Flow:** History range chips, Report "This year".
   - **Problem:** The chips and the age line use different sources (AGE vs CORPUS). "This year" is actually a rolling 365 days.
   - **Evidence:** :2570-2573, :3324-3332, :2354; HANDOFF:144.
   - **Fix:** Drive the chips, report ranges and age line from one record start. Rename the option "12 months".

**Navigation**

8. **Report has no tab and sits three levels deep.**
   - **Flow:** Tab bar -> Report.
   - **Problem:** HANDOFF lists the tabs as Today/History/Report/Settings. The prototype has Today/History/Trackers/Settings, and the only entry is Settings -> Data -> Report. Compare cannot send its pair to the report. The 15-report-sheet-pair.png screenshot is missing.
   - **Evidence:** HANDOFF:137; :1968-1984, :709, :1080.
   - **Fix:** Decide the tab set and fix the doc or the nav. Add Report entries from History and Compare. Restore the missing screenshot.

9. **Back paths ignore where the user came from, and the offline states have no route.**
   - **Problem:**
     - Day detail always goes back to History, even from Month or Tracker detail.
     - Reminder timing goes back to Nudge settings even when opened from the Today strip.
     - The "first open, caching" and "no connection" states are reachable only as frames.
   - **Evidence:** :908, :3882, :123, :1539, :2779, :1926.
   - **Fix:** Track the origin for back, as noteBack and restoreBack already do. Decide where the offline states surface, for example as a board strip.

10. **The amend entry disappears while an update strip is showing.**
    - **Flow:** Today -> Amend.
    - **Problem:** showAmend requires that no update strip is present, so a pending PWA update hides the time-limited grace path.
    - **Evidence:** :2801; screen 01.
    - **Fix:** Give amend a slot that nothing displaces (for example the lock chip), or stack the strips.

**Board controls and copy**

11. **"Nothing to log today" means two different operations, and it uses a banned word.**
    - **Flow:** Stepper pad vs notification, shortcut and widget.
    - **Problem:** On the pad it skips one tracker. As an action it skips the whole rest of the day, often on a partly written day. "log" breaks voice rule 2, and the copy audit kept it. On the amend board the pad still says "today".
    - **Evidence:** :238, :2504, :1382/1385, :3284-3286, :2531-2532; HANDOFF:275 and :343; audit line 223.
    - **Fix:** Label the pad key "Skip Focus" and the day action "Skip the rest of today". Use the day label on the notification, shortcut and widget alike.

12. **Skip can only be discovered from the day-one copy, and that copy is wrong.**
    - **Flow:** Today board in drag mode.
    - **Problem:** The only hint ("Tap the number to skip") appears on day one, when every value shows "–". The hint never adapts to stepper mode and never appears again.
    - **Evidence:** :2809/2811, :195, :2543; screen 02.
    - **Fix:** Add a persistent, quiet skip affordance. Make the hint mode-aware ("tap the dash").

13. **The large-text spec contradicts itself, and the toggle meaning is unclear.**
    - **Problem:**
      - The spec says "one row per screenful", but the screen shows about 5 rows that scroll with no scroll cue.
      - It is unclear whether the switch is a preview or an override of the OS text size.
      - Large and stepper modes drop yesterday's tick mark.
    - **Evidence:** HANDOFF:170 and :408; :2938, :3999, :2806-2809, :2518; screen 04.
    - **Fix:** Define how the OS size and the override combine. Fix the row-count claim, add a scroll cue, and show yesterday's value in these modes.

**Reminders and widget**

14. **The missed-reminder strip has no observable trigger and conflicts with the lapse strip.**
    - **Problem:** The strip asserts "The phone held it" as fact, though the app cannot know why a reminder was not delivered. The lapse strip (12–22 JUL, "no backlog") covers yesterday, which is still amendable, while the missed strip offers "Amend Wednesday" for the same day.
    - **Evidence:** :102-123, :2801; HANDOFF:349 and :395.
    - **Fix:** Define a trigger (reminder scheduled for yesterday and yesterday wholly blank). Soften the cause to "may have been held". Set precedence between the strips and keep an Amend path in the lapse state.

15. **The reminder is an offset in the spec but an absolute time in the UI.**
    - **Problem:** With a lock hour of 20, the default 21:30 nudge fires after the lock. The schedule panels hard-code 21:00 while the default is 21:30.
    - **Evidence:** HANDOFF:333; :3296-3297, :2758/2763/2768/2855, :3303.
    - **Fix:** Store the reminder as an offset before the lock, or clamp and flag absolute times. Render the user's chosen time in the copy.

16. **The reminder-permission timing is stated three ways, and day one promises "asks again tomorrow".**
    - **Problem:** The eyebrow says "AFTER A FEW DAYS", while the body and HANDOFF say after the first written day. The day-one copy promises a reminder before any permission or install exists.
    - **Evidence:** :1348/1483, :1356, :2811; HANDOFF:128, :322, :337.
    - **Fix:** Make the eyebrow match the real trigger. Make the day-one copy state the true next step and offer a reminder, or install first on iOS.

17. **The widget and badge count blanks while the copy says "written", and the post-lock state is undefined.**
    - **Evidence:** HANDOFF:135, :321, :345; :1412, :1428, :3275.
    - **Fix:** Use one quantity everywhere (blank sliders today). Specify what the widget and badge show from the lock to midnight and during the grace window.

**Lifecycle and data**

18. **Restore can silently overwrite locked days and has two incompatible conflict models.**
    - **Problem:** "Let the file win: 3 days overwritten" never lists which days or values change. HANDOFF puts ownership detection inside Restore, but the prototype splits it into a separate "Two devices" screen with a per-day merge that is never specified. "Keep them apart" never tells the other device it has stopped owning the file.
    - **Evidence:** :1196-1210, :3420/3424, :3366-3369; HANDOFF:152 and :398.
    - **Fix:** Show a diff before applying. Decide whether a restore may change a locked day and record it if so. Specify the merge and ownership rules.

19. **Restore refusal screens are unreachable, and onboarding restore skips the picker.**
    - **Problems:**
      - Both "Open" and the file rows go straight to the Restore diff.
      - The bad-file and old-file screens have no callers.
      - Onboarding jumps to a pre-filled file the picker never lists.
      - The refusal example (notes-export.md) could not get past a .json/.csv-only picker.
    - **Evidence:** :1667, :1675, :2690-2691, :2675, :2907, :3905, :2895-2897; HANDOFF:151 and :355-357.
    - **Fix:** Wire one route, Open -> refuse | older-file | diff. Send onboarding through the picker. Use a .json or .csv refusal example.

20. **The new-phone QR has no receiving side.**
    - **Problem:** The flow is "Take over from the old phone · scan" -> Restore. There is no scanner, pairing screen, camera permission or failure state. A serverless local-network transfer is unexplained, and HANDOFF says an export is the only way across.
    - **Evidence:** :724-727, :765-769, :3905-3907; HANDOFF:339.
    - **Fix:** Cut the QR path and use export, then restore, or design pairing on both phones, including the different-network case.

21. **Delete says exports cannot bring a tracker back, but Restore re-imports missing trackers.**
    - **Evidence:** :3238 vs :1200; HANDOFF:402.
    - **Fix:** Fix the copy, or have Restore ask about deleted trackers. Specify how trackers are matched (by id or name, and when types differ).

22. **First-run picks fill the Archive with trackers the user never had.**
    - **Problem:** Every unpicked starter is archived, so erase counts "11 trackers" and the "archiving all eight" copy does not match. There is no createdAt or archivedAt, so days outside a tracker's life count as blanks. There is no cap or overflow rule past eight trackers.
    - **Evidence:** :3412, :2277-2287, :3306; HANDOFF:3, :45-51, :387.
    - **Fix:** Leave unpicked starters out of the user's list. Add createdAt and archivedAt and exclude days outside a tracker's active span from blank counts. Set a maximum number of active trackers or design the overflow.

23. **The revision data model cannot express the older-file case it is meant to cover.**
    - **Problems:**
      - ScaleRevision has no trackerId.
      - Type comes from the label count, and type is immutable.
      - The editor allows only 5 or 2 steps, so a 3-word era cannot exist.
      - Old values at 0/5/10 land exactly on new word stops and will display as the wrong words.
      - The "1 June" boundary is just the file's date.
    - **Evidence:** HANDOFF:45-56, :49, :76, :361; :2908-2913, :3184.
    - **Fix:** Add trackerId and a stop count, or forbid stop-count changes. Define how old-era values display and where an imported boundary date comes from.

### Low

1. **"Written" is undefined, and the dot strip counts skipped rows as written.**
   - **Problem:** A day finished with "Nothing to log today" (all skips) counts as written. It is unclear whether it counts toward the 14-day report and 12-day pair thresholds. Screen readers announce "8 of 8 written" when 2 were skipped.
   - **Evidence:** :2793/2797; HANDOFF:140, :275, :295-296, :408.
   - **Fix:** Define "written day". Announce "n written, k skipped" or use "n of m done".

2. **The note footer implies notes freeze at the lock.**
   - **Problem:** Values stay amendable for the grace day, and day detail offers adding a note to yesterday.
   - **Evidence:** :3895 vs :3889.
   - **Fix:** Name the same close time as the values use.

3. **The weekday panel names a winner from about 4 days per bar.**
   - **Problem:** It shows no n and applies no noise threshold, unlike the pairs panel.
   - **Evidence:** :2595-2604; screen 06.
   - **Fix:** Show n and spread. Only name a weekday when the difference exceeds a noise threshold; otherwise say none stands out.

4. **Compare and This week leave out the range and n behind their claims.**
   - **Problem:** Compare has no date ends and silently uses the History range. This week shows means without n or per-tracker deltas, compares a partial week with a full one, and hard-codes "No other tracker moved much".
   - **Evidence:** :798-808, :2661, :3833-3846; HANDOFF:147.
   - **Fix:** Show the range and n. Qualify partial weeks ("4 of 7 days so far").

5. **Backup and restore file names disagree.**
   - **Problem:** The backup writes daytrack-latest.json, the picker lists dated files, and Restore shows a third file. It is unclear how a user would find the backup.
   - **Evidence:** :738, :2895-2897, :3905.
   - **Fix:** Use one naming scheme and label the backup in the picker.

## Open product questions

1. Is the lock hour a deadline (the day goes read-only until midnight) or the day boundary? Is it exactly HH:00? Is lock hour 0 allowed?
2. Is there any backup beyond a manual export? If yes, rule 1 and every privacy claim must change. If no, the backup and endpoint features go.
3. May a value ever change after its lock (grace day, restore with "file wins", wording correction)? If so, what does the provenance sheet disclose?
4. What does a tap on a value do, and is there a deliberate way to clear back to blank?
5. What is a "written day" for the thresholds: at least one value, all values set or skipped, or only set values?
6. Should wording corrections exist at all? And may a revision change the number of stops?
7. Is Report a tab? Should Compare be able to add a pair to it?
8. How does a user move phones: export and restore only, or a designed pairing flow?
9. On iOS, should the install prompt come before day one, or after it with a designed hand-over?
10. Is the reminder an offset from the lock or a clock time? When is permission asked?
11. Is there a cap on active trackers? What happens to unpicked starters?

---

I merged duplicates across the 4 lenses (lock time, tap-to-skip, provenance, cloud backup, "Nothing to log today", Report nav, onboarding restore, dot strip, day-one hint, back paths). I did not re-check the prototype files; line references come from the verified findings as given. The iOS separate-storage claim in High 7 is platform behaviour that could not be checked in the design files.
