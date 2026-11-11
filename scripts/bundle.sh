#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

app="dist/Hoboshell.app"

swift build -c release
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/Hoboshell "$app/Contents/MacOS/Hoboshell"
cp Support/Info.plist "$app/Contents/Info.plist"
identity="${HOBOSHELL_SIGN_IDENTITY:-Hoboshell Dev}"
if security find-identity -p codesigning | grep -q "\"$identity\""; then
  codesign --force --sign "$identity" "$app"
else
  codesign --force --sign - "$app"
fi

echo "$app"
