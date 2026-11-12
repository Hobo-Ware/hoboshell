#!/usr/bin/env python3
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
icons = sorted((root / "Design" / "icons").glob("*.svg"))
lines = ["enum HoboIconData {", "    static let svg: [String: String] = ["]
for icon in icons:
    text = " ".join(icon.read_text().split())
    if '"##' in text:
        raise SystemExit(f"{icon.name} holds the raw string end marker")
    lines.append(f'        "{icon.stem}": ##"{text}"##,')
lines += ["    ]", "}", ""]
(root / "Sources" / "Hoboshell" / "HoboIconData.swift").write_text("\n".join(lines))
print(f"embedded {len(icons)} icons")
