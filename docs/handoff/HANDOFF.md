# Daytrack — implementation handoff

A daily self-tracking app. Eight things, one screen, ten seconds. No account, no server, no cloud. Everything lives on the device.

This document is self-sufficient: you should be able to build Daytrack from it without seeing the prototype. Where it states a number, that number was measured out of the working prototype, not estimated.

## What is in this bundle

Everything below sits in this folder, next to this README. Open the `.dc.html` files in a browser directly — no build step, no server.

| File | What it is | How to use it |
|---|---|---|
| `Daytrack.dc.html` | The full interactive prototype: every screen, 57 frames, and the printed report sheets | **Start here.** The first frame is live — drag its sliders and every other frame follows. Scroll for the report sheets |
| `Design spec.dc.html` | Visual system: measured tokens with blue-channel figures, the full type scale, radii, component anatomy | The authority when this README and your eyes disagree on a number |
| `Copy audit.dc.html` | All 76 audited strings with exact shipped wording, plus the four voice rules and their rationale | Use as the copy deck. Do not paraphrase these strings |
| `manifest.webmanifest` | Production-ready PWA manifest: icons, shortcuts, colours | Ship as-is |
| `icons/` | Full icon set — favicons, apple-touch, 192/512 any + maskable, four shortcut glyphs, `icon.svg` | Ship as-is |
| `support.js` | The prototype's template runtime | Required for the `.dc.html` files to open. **Not** something to port |

The HTML files are **design references**, not production code. They are a single-file prototype using a small template runtime; do not port that architecture. Rebuild the UI in whatever the target codebase already uses (React Native, SwiftUI, Flutter, a real PWA), following that codebase's conventions. Fidelity is **high**: colours, type, spacing and copy are final and should be matched closely.

**Suggested reading order:** §1 product rules → open `Daytrack.dc.html` and use the live frame → §2 data model → §6 statistics. §§3–5 are reference you will come back to per screen. §§7–10 matter before you call any of it done.

---

## 1. Product rules — read these first

These are the decisions everything else depends on. Getting one wrong makes the app dishonest.

1. **Local only.** No account, no server, no analytics, no network calls. There is nothing to sign into and nothing to leak. Every privacy claim in the copy must remain literally true.
2. **A day locks at the lock hour** (default 23:00, user-configurable 0–23). After that the day is written and read-only, with exactly **one grace day**: yesterday is editable until today's lock hour, then never again.
3. **Blank and skipped are different things and are never merged.** A *blank* means nothing was written. A *skipped* value means the user asserted nothing happened worth writing. Neither enters an average; both are counted and reported separately.
4. **Nothing is ever imputed, interpolated, or carried forward.** A gap in a chart is drawn as a gap. This is the app's core credibility promise.
5. **No streaks, no encouragement, no gamification.** People use this to record how bad things are. A missed day is information, not a failure.
6. **A tracker's type is immutable after creation.** Renaming and re-iconing are free; changing the scale type is not offered.
7. **Changing the wording of a scale creates a revision boundary.** No statistic may ever cross one. See §6.

---

## 2. Data model

```ts
type TrackerType = 'numeric' | 'ordinal' | 'binary';

interface Tracker {
  id: string;
  name: string;
  icon: string;              // Font Awesome 6 Free Solid name, e.g. 'fa-moon'
  labels?: string[];         // absent = numeric 0–10; 5 items = ordinal; 2 items = binary
  archived: boolean;
}

interface ScaleRevision {
  effectiveFrom: DateOnly;   // wording changed ON this date
  previousLabels: string[];  // what the words were before
}

interface DayEntry {
  date: DateOnly;                              // local calendar date, the primary key
  values: Record<TrackerId, number | 'skip'>;  // absent key = blank
  note?: string;                               // one per day, max one
  writtenAt: Timestamp;
  tzOffsetAtWrite: number;
}
```

**Value encoding.** Store every value on a canonical 0–10 float scale regardless of type. Convert for display:

```
stops(tracker)   = tracker.labels ? tracker.labels.length : 11
toIndex(t, v)    = t.labels ? round(v / 10 * (t.labels.length - 1)) : v
```

So an ordinal tracker with 5 words stores 0, 2.5, 5, 7.5, 10 and displays `labels[0..4]`. A binary stores 0 or 10 and displays `labels[0..1]`. This is what lets two trackers of different types share a chart axis. **Do not store the label index** — it breaks the moment the wording is revised.

**Defaults.** Ordinal words `['Absent','Present','Mild','Moderate','Severe']`, binary `['No','Yes']`. Onboarding offers a starter set and requires at least one pick; there is no empty-list state.

**Storage.** Anything durable and local (SQLite, Core Data, IndexedDB). Requirements: survives app updates untouched, exports to plain JSON and CSV with no lock or expiry, and is fully deletable on request. Never write a value the user did not enter.

---

## 3. Screens

**Screenshots** are in `screens/`, captured at 2× from the prototype:

| File | Screen |
|---|---|
| `01-today-board.png` | The board — all three value types, a skip, a blank, the note |
| `02-day-one.png` | Day one, nothing written yet |
| `03-stepper-mode.png` | Stepper entry mode |
| `04-large-text.png` | Large-text mode |
| `05-history.png` | History with the range chart and tracker list |
| `06-tracker-detail.png` | One tracker over 90 days, skip/blank split, weekday panel |
| `07-week.png` | Week grid with per-tracker deltas |
| `08-compare-pairs.png` | Two trackers on one axis, then the split |
| `09-report-builder.png` | Report builder |
| `10-settings.png` | Settings, including the accent picker and night shade |
| `11-first-run.png` | Onboarding |
| `12-erased.png` | After erasing everything |
| `13-report-sheet-summary.png` | Printed summary sheet |
| `14-report-sheet-provenance.png` | Printed provenance sheet — the clinician-facing caveats |
| `15-report-sheet-pair.png` | Printed pair sheet |
| `16-schedule-iphone.png` | Reminder timing on iPhone — summary, Focus, no exact time |
| `17-schedule-android.png` | Reminder timing on Android — optimisation, doze, exact alarms |
| `18-reminder-missed.png` | A reminder the phone never delivered |
| `19-file-picker.png` | The system picker, drawn plain, and what the app can see |
| `20-restore-wrong-file.png` | A file with no days in it — read, refused, nothing touched |
| `21-restore-older-file.png` | An older file with a revised scale — boundary marked, nothing converted |
| `22-offline-stored.png` | Offline: what is stored on the phone |
| `23-offline-no-connection.png` | Offline with no connection — everything still working |
| `24-offline-first-open.png` | First open, shell still caching |
| `25-native-iphone.png` | Reminder timing if it ships native on iPhone |
| `26-native-android.png` | Reminder timing if it ships native on Android |
| `27-native-reminder.png` | The reminder screen, native — one prompt, two notification actions |
| `28-native-widget.png` | The real widget — counts, never values |
| `29-native-storage.png` | Storage, native — backup excluded, updates from the store |

The screenshots show one state each. The prototype has 57 frames covering the states they cannot: the day turning mid-entry, returning after a lapse, time-zone crossing, restore collisions, revision boundaries, a reminder the phone never delivered, a wrong file handed to Restore, an older file with a revised scale, and the app still caching itself on first open. Open it for those.


**Both packagings ship: a PWA and native apps.** Frames that exist in only one are badged above the phone — **PWA** for the home-screen build, **NATIVE** for the native one. An unbadged frame is identical in both, which is most of the app: the board, the record, every statistic, the report and the printed sheets never differ.

Seven surfaces do differ, and each has a frame on both sides:

| Surface | PWA | Native |
|---|---|---|
| Getting it | Add to home screen, prompted after day one is written | The store. No install screen |
| Reminder permission | Only possible once it is on the home screen; a tab cannot wake you | An ordinary system prompt after day one, refusable, asked once |
| Reminder timing | No exact-time guarantee on iOS; Android exact alarms unavailable | iOS calendar trigger fires at the time; Android can hold `SCHEDULE_EXACT_ALARM` |
| Notification actions | Under a long press on the nudge | Two actions on the notification itself, finishing without opening the app |
| Home screen | Icon badge with blanks remaining, ritual under a long press | A real widget: the count, the dot strip, the lock hour — never a value |
| Updates | Downloads in the background, applies on restart; "What changed" screen | From the store, already installed. No check and no update screen in the app |
| Storage risk | Removing the icon takes the record | Backup would put the record in a cloud unless excluded — see §8 |

The widget and the badge both show **how many days are written, never what any of them say**: a home screen is read by other people, and a value on it would leak the thing the app exists to keep private. This is a product rule, not a widget design choice.

Phone frame in the prototype is 390 × 844. Bottom nav is 74px with four items: Today, History, Report, Settings.

| Screen | Purpose | Notes |
|---|---|---|
| **Today (board)** | The whole ritual. One row per active tracker, all on one screen, no scrolling target | Day name at 30px. Dot strip shows *n* of *m* written. Never blocks on completeness |
| **Amend yesterday** | The grace day | Identical board, chip reads "until midnight". Locks silently at the lock hour |
| **Note** | One free-text note per day | Auto-saved, no save button. Reachable from board and day detail |
| **History** | Range chart + tracker list | Range grows with the record: under 30 days shows only "so far", then 30 / 90 / 12-month appear as they become real |
| **Tracker detail** | One tracker over the range | Chart, average, high, low, written count, skip/blank split, weekday panel, revision note if the range crosses one |
| **Day detail** | One past day, read-only | Every tracker's value that day, plus the note |
| **Week / Month** | Grid views | Week: 7 columns with per-tracker deltas. Month: calendar heat grid |
| **Compare (pairs)** | Two trackers, one axis, then a split of the mean | Needs 12 overlapping written days. Optional 1-day lag |
| **Report builder** | Range, trackers, sections, pairs | Needs 14 written days in range. Six sheet types |
| **Export** | CSV / JSON / Markdown / PDF / Health | States destination, contents, and that nothing is uploaded |
| **File picker** | Hand one file over | Precedes Restore. The OS owns the sheet; the app states that it sees only the file handed to it |
| **Restore** | Bring a file in | Detects collision with a concurrently-writing device and asks which one owns the file going forward |
| **Restore · refused** | Wrong file | States what was read, why it was refused, and that nothing changed. Never a bare "invalid file" |
| **Restore · older file** | Revised scale | Days come in on the wording they were written with; a boundary is marked and nothing is converted |
| **Reminder timing** | Per-OS truth | One screen, two switches: iPhone / Android and home screen / native. Four panels. Reached from the reminder screen |
| **Offline** | Storage + update check | Three states: stored, no connection, still caching on first open |
| **Manage / Edit tracker** | Reorder, archive, delete, create | Archive is non-destructive and keeps all history |
| **Empty states** | Day-one history, every-tracker-archived | Two frames, `historyEmpty` and `boardEmpty`. Specified in §9 |
| **Settings** | Lock hour, night shade, accent, entry mode, large text, storage, version | Accent picker is described in §4 |
| **Onboarding** | Pick first trackers | No account wall. Offers "I already have Daytrack days" → Restore |
| **Install / Nudge / Widget** | PWA surfaces | Install prompt appears only *after* day one is written, never before |
| **Erase everything** | Destructive | States exactly what is lost and that there was no other copy. Confirms with the real count |

### The slider row — the only component that really matters

Three interchangeable entry modes. All three write the same value; switching never alters stored data.

- **Drag** (default) — press anywhere on the track, including a direct tap-to-position. Track 9px, radius 5. Handle 5 × 23px, radius 3, scales to 1.18 while held. Yesterday's value is marked with a 1.5 × 6px tick so today has context. Numeric value 25px mono at −.02em; word value 14.5px Instrument at −.01em.
- **Stepper** — track drops to 6px and loses its handle; value becomes a 58 × 44px tap target that opens a pad of discrete choices plus a skip key. For tremor and anyone who would rather not drag.
- **Large** — one row per screenful. Track 14px, handle 8 × 32px, label 21px, value 27px.

Tapping a value directly toggles **skipped**. Every row is a native ARIA slider: `role="slider"`, `aria-valuenow/valuemax`, `aria-valuetext` reading the word not the number, arrow keys step, Home/End jump. Never below 44px for any hit target.

---

## 4. Visual system

All colour is oklch in hue band 60–100. **There is no grey** — a neutral grey reads blue against this palette. Lightness carries all hierarchy.

| Token | oklch | Hex | Blue ch. | Use |
|---|---|---|---|---|
| `--bg` | `.15 .022 62` | `#120903` | 1% | Screen behind everything |
| `--sf` | `.202 .028 64` | `#1f1408` | 3% | Cards, list groups |
| `--sf2` | `.262 .036 68` | `#302110` | 6% | Unfilled track, dividers |
| `--ln` | `.325 .042 70` | `#42301b` | 11% | Every border |
| `--tx` | `.875 .125 84` | `#fdcf6f` | 44% | Primary text — lightest token, still amber |
| `--dm` | `.70 .062 78` | `#b49a73` | 45% | Secondary text, icons at rest |
| `--ft` | `.638 .058 76` | `#a08764` | 39% | Captions, mono labels |
| `--ac` | `.795 .168 78` | `#f6ac00` | 0% | Fill, handles, CTA. One per screen |
| `--ok` | `.80 .155 100` | `#d5bf2c` | 17% | Confirmed state, **and** the second series on a two-line chart |

**Why:** the app is opened in the dark. Surfaces and the default accent stay at 0–11% blue channel. Text is allowed ~40% because legibility beats dogma. **Measure any new colour before shipping it.**

**Night shade** multiplies amber over the whole UI, 0–100%, default 35%. The palette is already blue-free at 0%.

**Accent picker (Settings).** Six options. Three sit inside the ceiling — Amber `#f6ac00` (0%), Ember `oklch(.775 .175 62)` (7%), Copper `oklch(.72 .19 50)` (1%). Three cannot and say so: Clay `oklch(.72 .17 44)` (25%), Moss `oklch(.78 .145 128)` (36%), Rose `oklch(.70 .175 22)` (42%). Over-ceiling swatches carry a `!` marker, the readout shows the measured figure, and selecting one shows a caution naming the cost and pointing at Night shade. Offering them with the number attached is the point; hiding them would not be honest.

### Type

**Instrument Sans** 400/500/600 and **IBM Plex Mono** 400/500. The split is **numerals against words**, not language against data: mono takes numbers, dates, counts and uppercase labels; Instrument Sans takes language *and* word-scale values, because "Moderate" is a measurement but still a word.

| Role | Spec |
|---|---|
| Hero | Instrument 600 · 38px · −.035em |
| Board day name | Instrument 600 · 30px · −.03em |
| Screen heading | Instrument 600 · 27px · −.03em |
| Sub-screen title | Instrument 600 · 23–25px · −.03em |
| Wordmark | Instrument 600 · 21px · −.035em |
| Row label | Instrument 500 · 15px · −.01em (21px in large mode) |
| Body | Instrument 400 · 12.5px / 1.6 |
| Numeric value | Plex Mono 400 · 25px · −.02em |
| Word value | Instrument 500 · 14.5px · −.01em |
| Mono label (uppercase) | Plex Mono 400 · 10px · +.1em |
| Caption | Plex Mono 400 · 11px / 1.5 |

**Tracking splits on brand vs interface, not size.** Wordmark and hero take −.035em; every interface display size takes −.03em whatever its size — which is why the 21px wordmark is tighter than the 30px board day. Numerals take −.02em, interface labels and word values −.01em, uppercase mono +.09 to +.14em, body none.

### Space and shape

Radius: `999px` pills · `18px` icon tile at 64 · `15px` icon tile at 52 · `14px` primary CTA and outer cards · `13px` settings/content cards and standalone dashed panels · `12px` swatches and inline tiles · `11px` nested panels · `10px` toggles and stepper keys · `5px` slider track · `2px` ticks. The icon tile runs ~28% of its own size (15/52 and 18/64); take 28.8% and round for a new size.

Related items cluster at gap 8 / 11 / 12. Sections separate with `margin-top` 22/26/28/30 — **treat 28 as the step** (8 of 19 uses) and leave it only when a screen is unusually dense or empty. Onboarding and print section labels sit at 34. Everything within a section uses flex `gap`, never per-item margins. Phone screens pad 26px top / 22px sides; printed sheets 52px top / 54px sides.

**No shadow on any surface** — elevation is lightness, and a shadow on near-black is invisible. The slider handle is the only exception: `0 2px 8px rgba(0,0,0,.5)`, purely to lift it off its own track.

Icons: Font Awesome 6 Free Solid, **12px glyph in a 15px slot**. The slot is wider than the glyph so mixed icons stay optically aligned.

Primary CTA: height 50, radius 14, `--ac` fill with near-black text, one per screen. Onboarding's start button is the single 52px exception. Disabled drops to `--sf2` / `--ft` and **states the reason underneath** rather than sitting dead.

### Motion

No entrance animations, no page transitions, and no motion setting because there is no effect to disable. Honour Reduce Motion globally, at the stylesheet level, not per component. The whole inventory is four declarations on one curve:

| Element | Property | Time | Suppressed when |
|---|---|---|---|
| Track fill | `width` | 160ms | dragging |
| Handle | `left` | 160ms | dragging |
| Handle | `transform` 1 → 1.18 | 120ms | dragging |
| Editor chevron | `transform` 0° → 90° | 180ms | — |

Curve is `cubic-bezier(.22,1,.36,1)` throughout, except the 120ms handle scale, which takes the browser default — it is a pressure cue, not a position, and easing it makes the finger feel late.

#### The eight-tap interaction, frame by frame

Eight tracks, one press each, ten seconds. The governing rule: **no motion may sit between a press and the value being visible.** On every entry path except the keyboard, the new value paints on the first frame after the event — the eased curve above never actually plays during a drag.

**1 · pointerdown (0ms).** The value is set from the press x immediately, not on first move. The pointer is captured, transitions on fill and handle are dropped in the same state change, and the handle jumps to 1.18. Because the transition string is removed on the frame the drag begins, the jump to the finger is instant rather than a 160ms slide from wherever the value used to be. The numeral recolours `--tx` → `--ac`, unanimated, as a "you are holding this" signal.

**2 · pointermove (per event).** The value is recomputed per pointer event and quantised to the stop grid — eleven stops for a 0–10 track, one per label otherwise. No interpolation, no smoothing: the fill width *is* the value. The handle snaps between stops rather than gliding, which is correct — the data is discrete and the control should not imply otherwise.

**3 · pointerup (120ms).** Transitions are restored on the same frame, but nothing moves — the value is already where the finger left it. The only motion that ever plays at the end of a drag is the handle relaxing 1.18 → 1. No commit flourish, no checkmark, no row collapse. The value standing still is the confirmation.

**Tap path.** The stepper pad opens with no transition, commits on tap, closes on the same frame. Two taps, zero animation. The setting exists for people who find aiming hard; a pad that animates open is a pad you have to wait for.

**Keyboard path.** Arrows step ±1, Home/End jump to the ends. This is the *only* path where the 160ms fill is visible on the board — the one case where the value changes without a finger already sitting at the destination.

#### Haptics — NATIVE only

One event: a **selection tick** each time the drag crosses a stop — `UISelectionFeedbackGenerator` on iOS, `CLOCK_TICK` on Android. Nothing on pointerup, nothing on the eighth track, nothing when the day closes. Eight tracks a night is roughly eighty ticks; a success buzz on top of that is punishment, and a celebration for recording a bad day is the exact tonal failure §5 exists to prevent.

**PWA:** the Vibration API is unavailable on iOS Safari and coarse elsewhere. Ship the tick native-only and degrade silently — no fallback, no setting, no explanation on screen.

#### Two rules for anyone extending this

- **The board never re-renders under a moving finger.** If the day-close boundary is reached mid-drag, the lock is deferred and fires on pointerup instead. Any future timed change to Today must defer the same way.
- **Reduce Motion changes nothing about the primary interaction** — the drag path has no motion to remove. Only the chevron and the keyboard fill stop easing. If a new effect would make the app feel different with Reduce Motion on, it does not belong here.

---

## 5. Voice

Five rules. They are not style preferences; each one prevents a specific failure.

1. **State the fact, then say why it is fine.** Never the fact alone — an empty state that only reports emptiness reads as a failure the user caused.
2. **Data is *written*, never logged, entered or recorded.** A day is written or it is blank; a tracker is skipped on purpose. Those are the only three words for the state of a value. The noun "the record" (the whole body of days) stays. Two exceptions, both on the printed sheet: "Patient-entered" and "Anything unrecorded" are clinicians' terms of art and read as evasion if softened.
3. **Every "not enough" carries a count, a reason and a remainder.** How many there are, why that is too few, how many more. Bare adjectives — thin, too few, not enough — are failures on their own.
4. **"Nothing" is reserved for three jobs:** what leaves the phone, what the app will not do without you, and the plain fact that no data exists. It is the strongest promise in the app; spending it on a flourish costs the privacy copy.
5. **Never congratulate, never scold.** No streaks, no "great job". The copy has to survive being read on a bad day.

The house style, in three shipped sentences:

> "A fresh phone has nothing to disagree with, so there is nothing to choose."
> "They stay blank. The chart will show the hole, and the hole is true."
> "The record starts the first time you write a day."

`Copy audit.dc.html` has all 76 audited strings with exact current wording — use it as the copy deck.

---

## 6. Statistics — the honesty rules

Get these wrong and the app lies to a clinician.

- **Averages exclude both blanks and skips.** Report `n` as values only, and skips separately as `+n skip`.
- **Pairs need 12 overlapping written days.** Below that, show the count, the threshold and the remainder — never a bare "not enough". If every value of A falls on one side of its own mean there is no split to draw; say so rather than printing a degenerate result.
- **Reports need 14 written days in range.** Below that, state how many there are, why a thin report reads as a weak case rather than an early one, and how many more are needed.
- **A pair split is a split of the mean.** No coefficient, no model, no significance test, no adjustment. Say so on the sheet. Pairs are chosen after seeing the data, and the sheet must disclose that.
- **Revision boundaries are absolute dates; every window is relative.** Convert before use. A statistic must never span two wordings: window it to the era after the most recent revision inside the range, mark the boundary on the chart, and show the reduced *n*. The prototype learned this the hard way — a boundary stored as "days ago" and used as a window length is correct only when the range ends today.
- **Weekly means are means of the days present in that week**, never of seven assumed days.

---

## 7. Printed report

Six sheet types, Letter 612 × 792, ink on warm white `#fbfaf7`, amber demoted to a spot accent. Print-native — no PDF library, just a print stylesheet. One sheet per section: **summary**, **provenance**, **one chart per tracker**, **one sheet per pair**, **day-by-day table**, **notes**. No section starts mid-sheet; pairs and the table do continue across sheets and say so in their captions.

Every footer carries the export date and "self-reported, not a clinical instrument", because loose sheets get separated from each other.

Vocabulary shifts on paper: the screen says *you*, the sheet says *the patient*. Clinical terms of art that would sound evasive in the app are correct here. The provenance sheet must state: patient-entered once daily on the day itself and not reconstructed at the visit; entries lock and cannot be edited after; scales are subjective, self-defined, **not validated instruments**, carrying no clinical units and no equal-interval guarantee; missing days are never imputed.

---

## 8. PWA surface

`manifest.webmanifest` and `icons/` are production-ready — use them as-is.

- Icon mark: amber tile `#f6ac00`, three dark `#2c1200` bars at 100% / 55% / 78% width. Corner radius 28.8% of tile size.
- Sizes: 16/32/48 favicons, `icon.svg`, 180 apple-touch, 192 + 512 any, 192 + 512 maskable (mark inset to ~69% to clear the safe circle).
- `theme_color` and the `theme-color` meta are both `#120903`, the app background. **Not** the accent — a bright amber OS chrome band would contradict the whole night-use premise.
- Four shortcuts, deep-linked via `?go=today|yesterday|skip|week`, each with a 96px glyph. Read the param on launch and dispatch. `go=skip` fills every remaining blank with `skip` and lands on the board.
- Icon badge shows blanks remaining and disappears at zero.
- Install prompt only after day one is written. Notification permission only after install — on iOS a reminder is impossible from a browser tab, and the copy says so.
- Reminders must state that the phone decides when they actually fire; the board is the record, not the notification.

### Reminder scheduling, per OS

One screen, two panels, switched by a segmented control. The app asks for a time; the OS decides. Both panels close on the same line: whatever the phone did, the day is untouched and still amendable until the lock hour.

**iPhone.** Reminders are possible only once Daytrack is on the home screen — Safari never offers one to a tab, and the reminder screen already says so. Beyond that, three OS behaviours must be disclosed and none of them can be worked around: a Scheduled Summary holds the reminder until the summary is delivered; a Focus mode silences it (it is on the lock screen when the mode ends, not lost); and there is no exact-time guarantee for a home-screen app, so 21:00 means near 21:00. The fourth is the severe one: deleting the icon takes the record with it, because there is no other copy. Say it here, next to the install copy, not only in Erase.

**Android.** Four: battery optimisation lets the phone hold the reminder until next unlock; Doze can delay it by up to an hour; Android 13+ can grant an exact alarm, and without one 21:00 is a window rather than a time; reminders live on a single notification channel ("Before the day locks"), so silencing it silences nothing else — there is nothing else. Plus the storage distinction: clearing the app's *cache* in system settings leaves the record, clearing its *storage* deletes it. Two different buttons, one letter apart in outcome.

Implementation: one local notification per day, scheduled at the lock hour minus the user's offset, cancelled the moment the day has no blanks left. Never re-schedule a missed one — see below.

**If it ships native, this panel changes and the rest of the app does not.** The screen carries a second switch — home screen / native — and the prototype has all four panels. Two facts leave and two arrive.

*Leaves:* the install requirement. Permission becomes an ordinary system prompt, asked after day one is written, refusable, and never asked twice. On iOS a native calendar trigger is genuinely scheduled for 21:00, so the honest sentence changes from "no exact-time guarantee" to "scheduled for the time; what can still move it is delivery, not scheduling". On Android a native app can hold `SCHEDULE_EXACT_ALARM` and fire on the minute, with `POST_NOTIFICATIONS` asked separately on 13+.

*Arrives:* **backup, which is the more dangerous of the two.** A native app's storage is in the device backup by default — iCloud on iOS, Auto Backup to Drive on Android — and that would put the record in a cloud, making every privacy claim in the app false. Daytrack excludes its store from backup and sets `allowBackup="false"`. This is not a preference; product rule 1 depends on it. It has a real cost and the copy states it: a restored phone arrives with no days, and an export is the only way across. Deleting the app still takes the record with it, now with nothing behind it.

Unchanged in both packagings: Scheduled Summary, Focus, battery optimisation and Doze all still hold or silence a delivered reminder, and the day survives all of it. That last sentence is the one line both panels share.

**Notification actions (native).** Two, on the notification itself: *Open* lands on the board at the first blank slider, and *Nothing to log today* writes the day as skipped on purpose — never as blank — and finishes without opening the app. Both are the same two operations the board offers, so nothing exists on the notification that is not already a rule of the app.

**The widget (native).** One size, count only: the day name, how many are left, the dot strip, and the lock hour. It redraws on write and at the day turn; there is no timeline to keep warm and nothing to fetch. It must never render a value, a word scale or a note.

**Updates (native).** There is no update surface in the app at all — the store owns it, and an update arrives already installed. The PWA's update strip and "What changed" screen are PWA-only, and the native storage screen states plainly that nothing in the app wants a network.

**A reminder that never arrived** is a board state, not an error. A strip on Today names the likely cause (Focus, a summary, deep sleep), states that yesterday is still blank and still amendable until tonight's lock hour, and offers Amend and "Why it was held". No apology, no catch-up, no re-fire.

### Export / restore file picker

The picker belongs to the OS and should look like the OS; the prototype draws it plain and labels it `SYSTEM PICKER` so nobody ships the mock. What must hold on every platform:

- Filter to what Daytrack writes (`.json`, `.csv`). A file the picker will not offer is not hidden from the user — it is simply not readable, and the copy says that rather than leaving a filter to look like surveillance.
- Scoped access only: one file, handed over deliberately. No folder enumeration, no persistent directory grant, and no permission prompt that would imply either. This is a privacy claim, so it must be literally true — use the document-picker API, not a directory grant, even where a directory grant is easier.
- Nothing is read until Open, and nothing touches the record until the screen after (Restore, which shows what will change and needs a second confirmation).
- Cancel is a no-op and says so.
- Export writes locally first and shares second, so the file exists whether or not the share sheet is used or the device is online.

**Two refusal states, both required.** *Not a Daytrack file:* name the file, state that it read fine but has no days in it, and that nothing on the phone changed and the file was left as-is — never a bare "invalid file". *Written by an older version:* readable, so bring it in on the wording it was written with, mark a revision boundary at that date, show the reduced count, and convert nothing. An importer that silently re-scores old days to the current wording breaks §6 and is the single worst bug available in this app.

### Offline and the service worker

The app is offline-first, so "offline" is not an error state and gets no error styling. One screen under Settings → Works with no signal, in three states:

- **Stored.** What is on the phone: the app itself (~412 KB), the record (days, notes, size), fonts and icons. Nothing is fetched during use.
- **No connection.** Everything still works, listed explicitly: writing, amending, charts, history, report and print, and export (the file is written locally; sending it on can wait). Status bar shows the offline glyph. The update check is the only thing that wants a network, and nothing is waiting on it.
- **First open, still caching.** The record is written before the shell finishes copying, and the copy says so: today is already safe, keep writing, it resumes where it stopped.

Service worker: precache the shell, fonts and icons on install; cache-first for everything, with no network fallback path that could block an entry. New versions download in the background and apply on restart only — the existing update strip and "What changed" screen already own that flow, and an update must never interrupt an entry or touch a written day. There is no analytics, crash reporting or clock sync, so there is nothing else that would use a connection if it had one.

**Still to build (deliberately out of prototype scope):** the platform-native notification scheduling and picker code itself, and the service worker implementation. If the target is native rather than a PWA, the service worker is moot and the backup exclusion above becomes the first thing to get right. The states, copy and behaviour they must produce are specified above.

---

## 9. Edge cases that must work

### Empty states — two dedicated frames

The record is empty for as long as it takes to write the first day, and every read-side screen has to hold up in that window. Two states, both reachable and both specified as frames:

**History on day one — `historyEmpty`.** The range chips are gone (there is no range to pick), the age line reads *no days written yet*, and a dashed panel states that nothing is averaged until there is something to average and nothing is estimated in the meantime. Below it, a short list of what arrives and when — the chart and this week at **1 day**, a line at **2 days**, a split between two trackers at **12 days**. The list closes on the point that matters: *nothing is locked. These are the points at which a drawing stops being misleading, not rewards.* Do not turn these into a progress bar, a streak, or an unlock. They are honesty thresholds, and the app must never appear to be withholding a feature.

The calendar-day affordance stays in the header even here. Jumping to a month you have not written yet is allowed and shows an empty month; the app does not gate navigation on data.

**Every tracker archived — `boardEmpty`.** Reachable from Trackers by archiving all eight. The dot strip is suppressed entirely rather than rendered as an empty bar, and a dashed panel states that the record is untouched — *archiving takes something off the board, not out of the past.* One outlined action, **Bring one back**, goes to Trackers. A closing line states that there is no nudge tonight either, since a reminder for a board with nothing on it would be asking about nothing.

**Already handled inline, no separate frame needed:** a chart range with no days written (`dEmpty`, the panel states a gap is kept as a gap), two trackers below the 12-day overlap floor (the split names the shortfall rather than drawing), a report range too thin to read (`repThin`, which offers a wider range instead), restore onto a fresh phone (`restoreFresh` — nothing to disagree with, so nothing to choose), and the nudge on an already-written day (*Nothing arrives tonight*).

**The rule behind all of them.** An empty state states the fact, says why it is fine, and offers the one action that changes it — never an illustration, never encouragement, never a count of what is missing framed as a deficit. A person opening Daytrack on day one has done nothing wrong.


- **Day one** — blank board, no history, no charts. Copy counts down to the first written day and never implies lateness. Frames: `historyEmpty`, `boardEmpty` (above).
- **Returning after a lapse** — gap days stay blank. No catch-up prompt, no streak language, no backfill.
- **Time zone crossing** — a day belongs to the date it was written on and closes at the lock hour on the clock in the user's hand. The app explains that the day got longer or shorter; it is never re-dated afterwards.
- **Day turning while on screen** — relabel to "yesterday", never reset. Values stay editable until the grace period ends.
- **Two devices writing one backup file** — detect, pause, and ask which device owns the file going forward. A whole day is the unit; last write replaces that day rather than merging fields.
- **Mixed-era statistics** — boundary marked, window narrowed to a single wording, reduced *n* shown.
- **Range with no written days** — the chart yields to a written message, not a blank frame. Aria and visible copy must agree.
- **All values identical** — no split to compute; say so instead of rendering a degenerate chart.
- **Archive vs delete** — archived keeps every day it ever wrote in history, charts and exports, and simply stops asking. Delete states the real count of days it will remove and that no already-made export is affected.

---

## 10. Accessibility

Native ARIA sliders with full keyboard support. Stepper mode for anyone who cannot drag. Large-text mode scaling the whole board, one row per screenful. 44px minimum on every target. Reduce Motion honoured globally. Word values announced as words, not numbers. Skipped announced as "skipped today", blank as "not written yet" — never "nothing".

The screens added last carry four more obligations:

- **The OS segmented control** is a `tablist` of two `tab`s with one `aria-selected`, each controlling its panel. Arrow keys move between them without wrapping; the panel is not focus-trapped. The label is the platform name alone — "iPhone", not "iPhone settings" — because the panel heading already says what is being shown.
- **The caching bar** is `role="progressbar"` with `aria-valuenow/valuemin/valuemax` in kilobytes and an `aria-valuetext` that reads the absolute figure, not a percentage: "280 of 412 kilobytes stored". It is polite, never assertive: announcing every step would talk over an entry in progress. When it completes it does not announce completion — nothing was waiting on it, and the screen says so.
- **The picker sheet** is a modal dialog: `role="dialog"`, `aria-modal`, focus moved to the first file row on open and restored to the row that opened it on dismiss. Escape cancels. Each file row announces name, then day count, then size, then date, in that order — the count is the thing being chosen. The filter chip is not interactive and is announced as part of the sheet's description, not as a control.
- **The refusal and boundary states** are the announced text, not a live region: they are whole-screen changes, so the heading takes focus and the reason is read as ordinary content. Never announce a refusal as an alert — nothing failed and nothing is at risk, which is precisely what the copy says.

A reminder that never arrived is announced as a plain board strip, not an alert, and never as a warning: the day is intact and the strip says so.

**Both packagings, one behaviour.** The notes above are written in ARIA because the PWA is the reference implementation; the native builds owe the same behaviour through their own APIs:

| Obligation | PWA | iOS | Android |
|---|---|---|---|
| Slider row | `role="slider"`, `aria-valuetext` reads the word | `UIAccessibilityTraitAdjustable` with increment/decrement, `accessibilityValue` the word | `SeekBar` with `stateDescription` set to the word |
| Packaging / OS switch | `tablist` with one `aria-selected` | Segmented control trait, selected state announced | `TabLayout` with selected state |
| Caching bar | `role="progressbar"`, absolute figures in `aria-valuetext`, polite | Announce on demand only — never a queued announcement mid-entry | Same: no `announceForAccessibility` while a row has focus |
| Picker sheet | `role="dialog"`, `aria-modal`, focus to the first row | The system picker is already accessible; do not re-wrap it | Same — use the platform picker, not a custom list |
| Refusal / boundary | Heading takes focus, read as content | `.screenChanged` with the heading, never `.announcement` | Focus the heading; never a Toast |
| Widget (native only) | — | Accessibility label reads "three still to write, locks at 23:00" — the count, never a value | Same wording via `contentDescription` |

The widget's label obeys the same privacy rule as its face: it announces how many are left and never what any of them say, because a screen reader is audible to the room.
