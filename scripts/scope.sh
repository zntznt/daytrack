#!/usr/bin/env bash
# Linux: fail if the branch diff touches a path outside the task's ```scope globs.
# Usage: scripts/scope.sh <TASK-ID>
set -euo pipefail
shopt -s globstar extglob
ID=${1:?usage: scripts/scope.sh <TASK-ID>}
cd "$(git rev-parse --show-toplevel)"
TASKS=(docs/plan/tasks/"$ID"-*.md)
[[ -f ${TASKS[0]} ]] || { echo "scope: no task file for $ID" >&2; exit 2; }

mapfile -t GLOBS < <(awk '/^```scope/{f=1;next} /^```/{f=0} f && NF {print $1}' "${TASKS[0]}")
# shortcut: [[ == ]] matching lets * cross "/", so a glob is looser than a path glob; fine for review guards.
bad=0
while IFS= read -r path; do
  ok=0
  for glob in "${GLOBS[@]}"; do
    # shellcheck disable=SC2053 # unquoted on purpose: the right side is a glob
    if [[ $path == $glob ]]; then ok=1; break; fi
  done
  if ((!ok)); then echo "out of scope: $path"; bad=1; fi
done < <(git diff --name-only origin/main...HEAD)
exit "$bad"
