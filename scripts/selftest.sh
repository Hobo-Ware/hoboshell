#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

report="${1:-$(mktemp -t hoboshell-selftest)}"
app="$(./scripts/bundle.sh | tail -1)"

rm -f "$report"
open -g -W -n "$app" --args --variant bottom-taskbar --selftest realtime --selftest-report "$report"
cat "$report"
grep -q "^realtime self-test: \([0-9]*\) of \1 steps passed" "$report"
