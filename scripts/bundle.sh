#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

app="dist/Hoboshell.app"

swift build -c release
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/Hoboshell "$app/Contents/MacOS/Hoboshell"
cp Support/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"

echo "$app"
