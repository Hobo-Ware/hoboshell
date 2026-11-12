#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

app="dist/Hoboshell.app"

swift build -c release
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/Hoboshell "$app/Contents/MacOS/Hoboshell"
cp .build/release/HoboshellProbe dist/HoboshellProbe
cp Support/Info.plist "$app/Contents/Info.plist"

iconset="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$iconset" "$app/Contents/Resources"
for side in 16 32 128 256 512; do
  swift scripts/render-svg.swift Design/icons/app.svg "$iconset/icon_${side}x${side}.png" "$side"
  swift scripts/render-svg.swift Design/icons/app.svg "$iconset/icon_${side}x${side}@2x.png" "$((side * 2))"
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$iconset")"
identity="${HOBOSHELL_SIGN_IDENTITY:-Hoboshell Dev}"
if ! security find-identity -p codesigning | grep -q "\"$identity\""; then
  identity="-"
fi
codesign --force --sign "$identity" dist/HoboshellProbe
codesign --force --sign "$identity" "$app"

echo "$app"
