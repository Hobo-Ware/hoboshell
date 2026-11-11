# Hoboshell

A Windows-style desktop shell for macOS. It draws its own taskbar, Start menu,
desktop and file explorer on top of the normal Mac desktop, using public macOS
APIs only. No System Integrity Protection changes, no private frameworks.

> **Status: early.** It compiles and the core logic is tested, but the
> interface has had very little hands-on use. Expect rough edges.

## What you get

- **Taskbar** along the bottom of the screen, on every desktop: Start button,
  file explorer button, one button per running app, window snap buttons and a
  clock. Click an app's button to bring it forward; click it again to hide it.
- **Start menu** with a searchable list of your installed apps. Type, press
  Enter, done.
- **Desktop** with your Desktop files as an icon grid. Double-click to open.
- **File explorer** with a sidebar (Home, Desktop, Documents, Downloads,
  Applications, drives), back / forward / up, an editable path bar, a details
  list and an icon grid, plus Open, Rename, Move to Trash and New folder.
- **Window snapping**: send the last used window to the left half, the right
  half, or the full area above the taskbar.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer (Xcode, or just the Command Line Tools)

## Run it

```sh
git clone https://github.com/Hobo-Ware/hoboshell.git
cd hoboshell
swift run
```

To quit, right-click an empty part of the taskbar and pick **Quit Hoboshell**,
or press Ctrl+C in the terminal.

### Permissions macOS will ask for

| Prompt | Why |
| --- | --- |
| Accessibility | To move and resize other apps' windows when you snap them. |
| Desktop, Documents, Downloads folders | To show their files on the desktop and in the file explorer. |

When you start it from a terminal, the Accessibility switch appears under your
terminal app's name in System Settings > Privacy & Security > Accessibility.

### Hiding the real Dock and desktop icons

Off by default. Turn it on for one run:

```sh
HOBOSHELL_HIDE_SYSTEM_UI=1 swift run
```

This sets the Dock to auto-hide with a very long delay and turns off Finder's
desktop icons, then restarts both. Your old settings are saved first and put
back when Hoboshell quits. If it ever quits badly, restore them by hand:

```sh
swift run Hoboshell --restore
```

## Limits you should know about

macOS does not let another app replace Finder or the Dock, so Hoboshell is an
overlay, not a replacement:

- The Mac menu bar stays at the top of the screen.
- Windows you maximise yourself can slide under the taskbar. The snap buttons
  keep clear of it.
- The file explorer does not appear in Cmd+Tab, because Hoboshell runs as a
  background agent.
- There is no Edit menu yet, so Cmd+C / Cmd+V do not work inside Hoboshell's
  own text fields.

## Development

```sh
swift build          # compile
./scripts/test.sh    # run the tests
```

Use `./scripts/test.sh`, not plain `swift test`: it also works on machines
that have the Command Line Tools but not full Xcode.

Code is split in two:

- `Sources/HoboshellCore` - logic with no windows (snap geometry, file
  listing). Unit tested.
- `Sources/Hoboshell` - the app itself: windows, panels and system calls.

Coding and testing rules are in [AGENTS.md](AGENTS.md). Work done so far is in
[CHANGELOG.md](CHANGELOG.md).

## Roadmap

- One taskbar button per window, not per app
- System tray area
- Alt-Tab style window switcher
- Keyboard shortcuts for snapping
- A script that packages a proper `.app`
- Other looks, such as a top bar with a side dock
