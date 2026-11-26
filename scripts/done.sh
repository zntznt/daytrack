#!/usr/bin/env bash
# Linux: the Definition of Done (docs/plan/README.md §4). Usage: scripts/done.sh <TASK-ID>
set -uo pipefail
ID=${1:?usage: scripts/done.sh <TASK-ID>}
cd "$(git rev-parse --show-toplevel)" || exit 1
TASKS=(docs/plan/tasks/"$ID"-*.md)
[[ -f ${TASKS[0]} ]] || { echo "done: no task file for $ID" >&2; exit 2; }
git fetch -q origin main || exit 1

echo "== 1/5 scope"
scripts/scope.sh "$ID" || exit 1

echo "== 2/5 size"
LINES=$(git diff --numstat origin/main...HEAD -- . ':!docs/handoff' | awk '$1 != "-" {s += $1 + $2} END {print s + 0}')
echo "$LINES changed lines"
((LINES <= 400)) || { echo "size: over 400 lines; propose a split"; exit 1; }

echo "== 3/5 commits"
BAD=$(git log --format=%s origin/main..HEAD | grep -vE '^(feat|fix|test|refactor|docs|build|chore|perf)(\([a-z0-9.-]+\))?: .+')
[[ -z $BAD ]] || { echo "commits: not conventional:"; echo "$BAD"; exit 1; }
if git log --format=%B origin/main..HEAD | grep -iE 'co-authored-by|generated with|ai-generated'; then
  echo "commits: attribution is not allowed"; exit 1
fi

echo "== 4/5 scripts/mac all"
scripts/mac all || exit $?

echo "== 5/5 named tests"
MISSING=0
while IFS= read -r name; do
  grep -F -- "$name" .verify/last.log | grep -q passed || { echo "tests: '$name' did not pass"; MISSING=1; }
done < <(awk '/^```tests/{f=1;next} /^```/{f=0} f && NF {print $1}' "${TASKS[0]}")
((!MISSING)) || exit 1

echo "Also run: any commands the task lists under **Also run** (not run here)."
echo "DONE OK $ID"
