#!/bin/sh
set -eu

out="${1:?usage: scripts/capture.sh OUTPUT_FOLDER}"
mkdir -p "$out"

swift - <<'SWIFT' | while read -r id name; do
import CoreGraphics
import Foundation

let options: CGWindowListOption = [.optionOnScreenOnly]
let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
for window in windows where window[kCGWindowOwnerName as String] as? String == "Hoboshell" {
    guard let id = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
          let layer = window[kCGWindowLayer as String] as? Int else { continue }
    let width = Int(bounds["Width"] ?? 0)
    let height = Int(bounds["Height"] ?? 0)
    print("\(id) layer\(layer)-\(width)x\(height)-\(id)")
}
SWIFT
  if screencapture -x -o -l "$id" "$out/$name.png" 2>/dev/null; then
    echo "$out/$name.png"
  else
    echo "could not capture window $id: the terminal needs the Screen Recording permission" >&2
  fi
done
