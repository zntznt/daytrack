# Daytrack: agent entry point

Daytrack is a private, on-device daily self-tracking app for iOS (SwiftUI, Liquid Glass).

## Before any task
1. Read `docs/plan/AGENT_BRIEF.md`.
2. Then read your task file in `docs/plan/tasks/`, and only the sections it lists under **Read**.

## When docs disagree, the higher source wins
1. `docs/decisions.md`: "Owner decisions", then "Rule changes", then the Q sections and their amendments.
2. `docs/design-review.md`: never reproduce a listed defect.
3. `docs/handoff/HANDOFF.md`: product rules, data model, screens, stats, edge cases, accessibility.
4. `docs/handoff/Copy audit.dc.html`: the copy deck. Use its strings exactly; decisions.md overrides it.
5. `docs/handoff/Daytrack.dc.html` and `docs/handoff/screens/*.png`: flow and copy only, never visuals.

## Never
- Make network calls, add analytics, or add dependencies.
- Edit outside your task's scope block, or push to `main`.
- Add AI attribution to commits or PRs.

## Definition of Done
`scripts/done.sh <ID>` exits 0.
