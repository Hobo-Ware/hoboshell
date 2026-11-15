#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ]; then
  echo "usage: scripts/release.sh VERSION" >&2
  exit 2
fi

version="$1"
plist="Support/Info.plist"
repo_url="https://github.com/Hobo-Ware/hoboshell"
sign_update=".build/artifacts/sparkle/Sparkle/bin/sign_update"

for key in CFBundleShortVersionString CFBundleVersion; do
  found="$(plutil -extract "$key" raw "$plist")"
  if [ "$found" != "$version" ]; then
    echo "$plist says $key is $found, not $version. Bump both version keys first." >&2
    exit 1
  fi
done

HOBOSHELL_SIGN_IDENTITY=- ./scripts/bundle.sh

if [ ! -x "$sign_update" ]; then
  echo "Sparkle's sign_update is missing at $sign_update. Run swift build first." >&2
  exit 1
fi

zip="dist/Hoboshell-$version.zip"
appcast="dist/appcast.xml"
rm -f "$zip" "$appcast"
ditto -c -k --keepParent dist/Hoboshell.app "$zip"

if [ -n "${HOBOSHELL_ED_KEY_FILE:-}" ]; then
  signature="$("$sign_update" --ed-key-file "$HOBOSHELL_ED_KEY_FILE" "$zip")"
else
  signature="$("$sign_update" "$zip")"
fi
case "$signature" in
  *sparkle:edSignature=*length=*) ;;
  *)
    echo "sign_update printed no signature: $signature" >&2
    exit 1
    ;;
esac

published="$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")"
cat > "$appcast" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Hoboshell</title>
        <item>
            <title>Hoboshell $version</title>
            <pubDate>$published</pubDate>
            <sparkle:version>$version</sparkle:version>
            <sparkle:shortVersionString>$version</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="$repo_url/releases/download/v$version/Hoboshell-$version.zip" type="application/octet-stream" $signature />
        </item>
    </channel>
</rss>
XML

echo "$zip"
echo "$appcast"
