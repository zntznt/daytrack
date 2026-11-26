# Agent brief (read before every task)

You are building **one task** of Daytrack, a private daily self-tracking app for iOS. It runs on the device only. The task file you were given is your whole assignment. Finish it, prove it, open the PR, and stop.

## 1. What to read, and in which order

1. This brief.
2. Your task file: `docs/plan/tasks/<id>-<slug>.md`.
3. Only the sections listed under **Read** in the task file. Do not browse other docs "for context". That is how drift starts.
4. `docs/plan/README.md`, but only §3 (workflow), §4 (Definition of Done) and §6 (test infrastructure) if you need them.

**When docs disagree, the higher source wins:**
1. `docs/decisions.md`: "Owner decisions", then "Rule changes", then the Q sections and their amendments.
2. `docs/design-review.md`: never reproduce a listed defect.
3. `docs/handoff/HANDOFF.md`: product rules, data model, screens, stats, edge cases, accessibility.
4. `docs/handoff/Copy audit.dc.html`: the copy deck. Use its strings exactly. Copy in decisions.md overrides it.
5. `docs/handoff/Daytrack.dc.html` and `docs/handoff/screens/*.png`: flow and copy only. **Never use them for visuals.** Search the prototype with `rg`; do not read it whole.

**Native deltas: HANDOFF content that no longer applies. Do not build any of it.**
- All PWA material: install prompts, the service worker, the manifest, the offline caching state, update strips, the icon badge, Q9 and Q10b.
- All Android material.
- Automatic backup, the backup endpoint and QR phone pairing (Q2, Q8).
- The same-day lock, and any "locks tonight" copy (Q1).
- "Tapping a value toggles skipped" (Q4). A tap opens the choice pad.
- "Lock hour minus offset" and exact alarms (Q10). The reminder is an absolute local time.
- Font Awesome icon names. Use SF Symbols.
- The flat-dark palette in HANDOFF §4. The look is Liquid Glass over a warm ambient background. §4's type hierarchy, spacing, motion rules and "no grey" still guide you.

## 2. How to stay on task

- Touch only the paths in the task's ```` ```scope ```` block. `scripts/scope.sh <ID>` fails the task otherwise.
- Do everything in the Goal and nothing in **Out of scope**. If you find needed work outside the scope, write one line about it under **Follow-ups** in the PR body and do not do it.
- Implement exactly the named tests, with exactly those names. You may add more tests, but you may not rename or drop the named ones.
- Do not refactor code you were not asked to touch. Do not add options, settings, abstractions or "for later" hooks.
- Do not add dependencies. That covers Swift packages, CocoaPods, scripts that download anything, and fonts.
- Every user-facing string that depends on data (times, counts, tracker names, day labels) comes from `DaytrackCore/Copy`. Do not build those strings inside a view.
- Views follow container-presentational. `XxxView` takes plain values and closures. Only `XxxContainer` talks to use cases.
- When behaviour is not specified anywhere, check whether the task names a proposed default (**[O1]**…**[O10]**, see README §8). If it does, implement the default and flag it in the PR. If it does not, **stop and ask the owner one question.** Do not guess.

## 3. How to verify

You edit on Linux, in `/home/znt/repos/daytrack`. The Mac builds through rex. Never edit files on the Mac.

```
git switch -c <type>/<id-lowercase>-<slug> main     # or stack on an unmerged dependency's branch
# …edit, then commit (conventional commit, no attribution)…
scripts/mac core <Suite>                            # fast loop for domain work
scripts/mac app DaytrackUITests/<Class>             # one UI test class
scripts/done.sh <ID>                                # the Definition of Done; must exit 0
```

`scripts/done.sh` checks, in order: scope, the 400-line size limit, commit messages, `scripts/mac all`, and that every name in the task's ```` ```tests ```` block passed. Then run any **Also run** commands the task lists, and paste their output into the PR.

Exit codes from `scripts/mac`: 2 means you are on main or have uncommitted changes, 3 means the Mac checkout is dirty (stop and tell the owner; do not clean it), 4 means xcodegen is missing, 5 means the simulator is missing, 64 means an unknown target. Any other non-zero code is a real failure. Read `.verify/last.log`.

## 4. When to stop and report

Stop, push what you have, and report in the PR (or to the owner if there is no PR yet) when any of these happens:
- `done.sh` passes. Open the PR and you are finished. Do not start the next task.
- The diff would exceed 400 lines. Propose a split.
- A spec gap has no **[O#]** default. Ask one question.
- A platform assumption fails, such as an API that behaves differently from what the task expects. Record what you observed and stop.
- `scripts/mac` exits 3, 4 or 5, or the Mac is unreachable.
- The same failing test has resisted three honest attempts at a fix.

## 5. Never

- **Never add network code**: `URLSession`, `URLRequest`, `NWConnection`, `Network`, `WebKit`, analytics or crash SDKs. Rule 1: no server, no network, no analytics.
- Never write a value the user did not enter. Never merge skip and blank. Never impute, interpolate or carry a value forward. Draw a gap as a gap.
- Never change a closed day, and that includes restore. Never move `closedThrough` backward.
- Never let a statistic cross a wording revision boundary.
- Never ship copy with "logged", "entered", "recorded", streaks or encouragement. Values are *written*.
- Never hard-code a lock time ("23:59", "until midnight", "LOCKS 23:00"). Derive it from the lock hour through `Copy`.
- Never reproduce a `design-review.md` defect. Your task names the relevant ones.
- Never ask for notification permission at launch. Never re-prompt after a refusal.
- Never show a tracker value in the widget.
- Never leave an export file (copy, CSV, PDF) inside the app after its sheet closes. Exports live in `tmp/Exports/` only while shared.
- Never edit outside your scope, never push to main, never merge, never edit the Mac checkout, and never add `Co-Authored-By` or AI attribution.
