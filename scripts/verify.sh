#!/usr/bin/env bash
# Mac: build, test and lint the checked-out commit. Run through scripts/mac from Linux.
# Usage: scripts/verify.sh core|app|lint|lint-selftest|all|shots|device [arg]
set -euo pipefail
cd "$(dirname "$0")/.."
REPO=$PWD
SIM=${SIM:-iPhone 18 Pro}
DEVICE=${DEVICE:-}
TARGET=${1:-}
ARG=${2:-}
DEST="platform=iOS Simulator,name=$SIM"

usage() { echo "usage: scripts/verify.sh core [Filter] | app [OnlyTesting] | lint | lint-selftest | all | shots <screen> | device" >&2; return 64; }

# --- lint ---------------------------------------------------------------------------------------

# scan FLAGS PATTERN DIR...: print path:line:text for matching lines in .swift files under existing DIRs.
scan() {
  local flags=$1 pat=$2 d
  shift 2
  for d in "$@"; do
    [[ -d $d ]] || continue
    find "$d" -name '*.swift' -not -path '*/build/*' -not -path '*/.build/*' -print0 \
      | xargs -0 grep -nH $flags -E "$pat" 2>/dev/null || true
  done
}

# shortcut: a literal is text between two quotes on one line, so multi-line """ strings are not checked.
LIT='"[^"]*'
END='[^"]*"'

# lint ROOT: apply every rule to the tree at ROOT. Prints "lint rule N: ..." per broken rule.
lint() (
  cd "$1"
  fail=0
  report() { if [[ -n $3 ]]; then printf 'lint rule %s: %s\n%s\n' "$1" "$2" "$3"; fail=1; fi; }
  report 1 "DaytrackKit/Sources imports only Foundation or DaytrackCore" \
    "$(scan '' '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]' DaytrackKit/Sources \
      | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+(Foundation|DaytrackCore)([^A-Za-z0-9_.]|$)' || true)"
  report 2 "no network code under App/, Widget/ or DaytrackKit/" \
    "$(scan '' 'URLSession|URLRequest|NWConnection|import[[:space:]]+Network|WKWebView|import[[:space:]]+WebKit' App Widget DaytrackKit)"
  report 3 "no drifted lock strings in string literals" \
    "$(scan -i "$LIT(23:59|until midnight|LOCKS 23|Before the day locks)$END" .)"
  report 4 "no banned copy in string literals (exceptions: scripts/lint-allow.txt)" \
    "$(scan -i "$LIT(logged|Nothing to log|streak|great job)$END" . \
      | grep -vFf <(grep -vE '^[[:space:]]*(#|$)' "$REPO/scripts/lint-allow.txt") || true)"
  report 5 "every List or Form under App/ uses .daytrackList()" \
    "$(scan -l 'List \{|Form \{' App | while read -r f; do grep -qF '.daytrackList()' "$f" || echo "$f"; done)"
  exit "$fail"
)

# lint-selftest: a clean tree passes, and each rule fires on its own violating fixture.
selftest() {
  local tmp fail=0
  tmp=$(mktemp -d)
  fixture() { mkdir -p "$1/$(dirname "$2")" && printf '%s\n' "$3" > "$1/$2"; }

  fixture "$tmp/clean" DaytrackKit/Sources/DaytrackCore/Ok.swift 'import Foundation'
  fixture "$tmp/clean" App/Ok.swift 'let s = "Written"'
  if lint "$tmp/clean"; then echo "lint-selftest: clean tree passes"; else echo "lint-selftest: clean tree FAILED"; fail=1; fi

  expect() {
    local out
    fixture "$tmp/rule$1" "$2" "$3"
    out=$(lint "$tmp/rule$1" || true)
    if grep -q "^lint rule $1:" <<<"$out"; then echo "lint-selftest: rule $1 fires"; else echo "lint-selftest: rule $1 did NOT fire"; fail=1; fi
  }
  expect 1 DaytrackKit/Sources/DaytrackCore/Bad.swift 'import SwiftUI'
  expect 2 App/Bad.swift 'let s = URLSession.shared'
  expect 3 App/Bad.swift 'let s = "Open until 23:59"'
  expect 4 App/Bad.swift 'let s = "Nothing to log"'
  expect 5 App/Bad.swift 'var body: some View { List { Text("a") } }'
  rm -rf "$tmp"
  return "$fail"
}

# --- build and test ------------------------------------------------------------------------------

need_xcodegen() { command -v xcodegen >/dev/null || { echo "xcodegen is missing (owner gate G1)" >&2; return 4; }; }
# sim_udid: print the UDID of the available simulator named $SIM, or return 5.
sim_udid() {
  local udid
  udid=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -n 1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  [[ -n $udid ]] || { echo "simulator '$SIM' is not available" >&2; return 5; }
  echo "$udid"
}

core() {
  [[ -d DaytrackKit ]] || { echo "no package yet"; return 0; }
  swift test --package-path DaytrackKit ${ARG:+--filter "$ARG"}
}

app() {
  need_xcodegen || return $?
  sim_udid >/dev/null || return $?
  xcodegen generate --quiet || return 1
  mkdir -p build
  local rc=0
  xcodebuild test -project Daytrack.xcodeproj -scheme Daytrack -destination "$DEST" -derivedDataPath build/DD \
    ${ARG:+"-only-testing:$ARG"} > build/xcodebuild.log 2>&1 || rc=$?
  grep -E 'Test (Case|case)|✔|✘|error:|\*\* TEST' build/xcodebuild.log || true
  return "$rc"
}

shots() {
  [[ -n $ARG ]] || { usage; return 64; }
  need_xcodegen || return $?
  local udid app bid
  udid=$(sim_udid) || return $?
  xcodegen generate --quiet || return 1
  mkdir -p build/shots
  xcodebuild build -project Daytrack.xcodeproj -scheme Daytrack -destination "$DEST" -derivedDataPath build/DD \
    > build/xcodebuild.log 2>&1 || { tail -n 40 build/xcodebuild.log; return 1; }
  app=build/DD/Build/Products/Debug-iphonesimulator/Daytrack.app
  bid=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")
  xcrun simctl boot "$udid" 2>/dev/null || true # already booted is fine
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl install "$udid" "$app"
  shot() {
    local variant=$1
    shift
    xcrun simctl terminate "$udid" "$bid" 2>/dev/null || true
    xcrun simctl launch "$udid" "$bid" -uiTestScreen "$ARG" "$@" >/dev/null
    sleep 3 # let the screen settle before the capture
    xcrun simctl io "$udid" screenshot "build/shots/$ARG-$variant.png"
  }
  shot default
  shot reduceTransparency -uiTestLegibility reduceTransparency
  shot increaseContrast -uiTestLegibility increaseContrast
  shot accessibilityXXXL -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL
}

device() {
  need_xcodegen || return $?
  [[ -n $DEVICE ]] || { echo "DEVICE is not set" >&2; return 1; }
  xcodegen generate --quiet || return 1
  mkdir -p build
  xcodebuild -project Daytrack.xcodeproj -scheme Daytrack -configuration Release -destination "id=$DEVICE" \
    -derivedDataPath build/DD -allowProvisioningUpdates -allowProvisioningDeviceRegistration build > build/xcodebuild.log 2>&1 \
    || { tail -n 40 build/xcodebuild.log; return 1; }
  xcrun devicectl device install app --device "$DEVICE" build/DD/Build/Products/Release-iphoneos/Daytrack.app
}

case $TARGET in
  core) core ;;
  app) app ;;
  lint) lint "$REPO" && echo "lint OK" ;;
  lint-selftest) selftest ;;
  all) selftest && lint "$REPO" && core && app ;;
  shots) shots ;;
  device) device ;;
  *) usage ;;
esac
