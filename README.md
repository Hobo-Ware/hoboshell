# Hoboshell

A Windows-style desktop shell for macOS. It draws its own taskbar, Start menu,
desktop and file explorer on top of the normal Mac desktop, using public macOS
APIs only. No System Integrity Protection changes, no private frameworks.

> **Status: early.** It compiles and the core logic is tested, but the
> interface has had very little hands-on use. Expect rough edges.

## What you get

- **Taskbar** along the bottom of the screen, on every desktop: Start button,
  file explorer button, one button per open window, the tray and a show
  desktop strip. Everything on it lights up under the pointer. Click a window's button to bring it forward; click it
  again to minimise it. Right-click a button to pin the app, close its
  windows or quit it. Pinned apps stay on the bar, running apps get a line
  under the button, and many windows of one app can fold into one button.
- **System tray** with network state, battery level, and a clock with the date.
- **Window switcher**: hold Option and press Tab to step through open windows,
  release Option to switch.
- **Start menu** with a searchable list of your installed apps. Type, press
  Enter, done.
- **Desktop** with your Desktop files as an icon grid. Double-click to open.
- **File explorer** with a sidebar (Quick access, drives, Trash), back /
  forward / up, a clickable path bar, search, a details list and an icon
  grid, plus cut, copy, paste, rename in place, Move to Trash, sorting, drag
  and drop and Quick Look.
- **Window snapping** (keyboard): send the last used window to the left half, the right
  half, or the full area above the taskbar.

## Looks

Hoboshell has two looks. Right-click any Hoboshell bar to switch; your choice
is remembered.

| Look | What you see | Start with |
| --- | --- | --- |
| Bottom taskbar (default) | One bar along the bottom with Start, window buttons and the tray | `swift run Hoboshell --variant bottom-taskbar` |
| Top bar and side dock | A slim bar under the Mac menu bar with Activities and the tray, plus an icon dock on the left | `swift run Hoboshell --variant top-bar-dock` |

## Keyboard shortcuts

| Keys | What happens |
| --- | --- |
| Option+Tab | Step through open windows; release Option to switch |
| Control+Option+Left | Snap the last used window to the left half |
| Control+Option+Right | Snap it to the right half |
| Control+Option+Up | Fill the area above the taskbar |

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
| Screen Recording (optional) | To draw the live picture on the card that appears when you rest the pointer on a taskbar button. Without it the card shows the app icon. |
| Accessibility | To list other apps' windows on the taskbar, switch between them, and move them when you snap. Without it the taskbar shows one button per app. |
| Desktop, Documents, Downloads folders | To show their files on the desktop and in the file explorer. |

When you start it from a terminal, the Accessibility switch appears under your
terminal app's name in System Settings > Privacy & Security > Accessibility.

### Hiding the real Dock and desktop icons

Off by default. Right-click a bar and tick "Hide the Mac Dock and desktop
icons"; the choice is remembered. Or turn it on for one run:

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
- Windows you maximise yourself can slide under the taskbar. The snap shortcuts
  keep clear of it.
- The file explorer does not appear in Cmd+Tab, because Hoboshell runs as a
  background agent. It does appear on the taskbar and in Option+Tab.
- The system tray shows Hoboshell's own indicators. macOS does not let another
  app host the real menu bar icons.
- The window list is refreshed every second or two, so a new window can take a
  moment to appear on the taskbar.

## Development

```sh
swift build          # compile
./scripts/test.sh    # run the tests
./scripts/bundle.sh  # build a signed dist/Hoboshell.app
```

Every pull request that is ready for review gets the same build and test run
on GitHub Actions.

Use `./scripts/test.sh`, not plain `swift test`: it also works on machines
that have the Command Line Tools but not full Xcode.

Code is split in two:

- `Sources/HoboshellCore` - logic with no windows (snap geometry, file
  listing). Unit tested.
- `Sources/Hoboshell` - the app itself: windows, panels and system calls.

Coding and testing rules are in [AGENTS.md](AGENTS.md). Work done so far is in
[CHANGELOG.md](CHANGELOG.md).

## Roadmap

- Volume control in the system tray
