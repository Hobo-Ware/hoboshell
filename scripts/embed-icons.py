#!/usr/bin/env python3
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
icons = sorted((root / "Design" / "icons").glob("*.svg"))
packs = sorted((root / "Design" / "icon-packs").glob("*/*.svg"))
lines = ["enum HoboIconData {", "    static let svg: [String: String] = ["]
for icon in icons + packs:
    text = " ".join(icon.read_text().split())
    if '"##' in text:
        raise SystemExit(f"{icon.name} holds the raw string end marker")
    key = icon.stem if icon in icons else f"{icon.parent.name}/{icon.stem}"
    lines.append(f'        "{key}": ##"{text}"##,')
lines += ["    ]", "}", ""]
(root / "Sources" / "Hoboshell" / "HoboIconData.swift").write_text("\n".join(lines))
print(f"embedded {len(icons)} icons and {len(packs)} pack icons")
