#!/bin/sh
set -eu

report="${1:-}"
swift build
binary="$(swift build --show-bin-path)/Hoboshell"

if [ -n "$report" ]; then
  exec "$binary" --variant bottom-taskbar --selftest realtime --selftest-report "$report"
fi
exec "$binary" --variant bottom-taskbar --selftest realtime
