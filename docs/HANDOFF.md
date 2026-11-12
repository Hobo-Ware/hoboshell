# Handoff - where Hoboshell stands

This file is the starting point for whoever picks the work up next, person or agent. Read `AGENTS.md` first; it holds the rules. This file holds the state.

## Where the work is

Nothing below is merged into `main` yet. The work sits in a stack of draft pull requests, each based on the one before it. **Check out the top branch, `feat/realtime-engine`, to get everything.**

| Order | Pull request | Branch | What it holds |
| --- | --- | --- | --- |
| 1 | #6 | `fix/taskbar-tray-and-snap` | First fix round: tray layout, hover, desktop icons, Dock switch |
| 2 | #7 | `feat/taskbar-cards` | Preview cards and right-click menu on taskbar buttons |
| 3 | #8 | `feat/explorer-rebuild` | Two-pane file explorer |
| 4 | #9 | `feat/design-system` | Design system, gallery window, signing with a fixed certificate, capture script |
| 5 | #10 | `feat/taskbar-parity` | Pins, grouping, running marks, group cards, badges, overflow |
| 6 | #11 | `feat/hobo-icons` | The icon set and the app icon |
| 7 | #12 | `feat/start-menu` | Start menu: pins, all apps, recent, search, rail, power footer |
| 8 | #13 | `fix/explorer-polish` | Explorer look: icons view, toolbar rows, path bar, details view |
| 9 | #14 | `feat/switcher-and-fixes` | Per-window Command+Tab switcher, Start and taskbar fixes |
| 10 | #15 | `feat/dock-reserve` | Maximised windows stop at the taskbar (the real Dock reserves the space) |
| 11 | #16 | `feat/tray` | Background apps in the tray, volume, calendar, battery, network popups |
| 12 | #17 | `feat/realtime-engine` | Event-driven shell state, bars updated by diff, self-test |

PR #5 (`chore/gpl-license`) is separate and ready; it adds the license.

Merging is the owner's call. The stack merges in order, #6 first.

## Setting up a new Mac

1. Install the Command Line Tools (`xcode-select --install`). Full Xcode is not needed.
2. `swift build`, then `./scripts/test.sh`. Expect `Test run with 510 tests in 63 suites passed`.
3. Create a signing certificate so macOS permissions survive rebuilds: Keychain Access > Certificate Assistant > Create a Certificate, name `Hoboshell Dev`, Identity Type "Self Signed Root", Certificate Type "Code Signing". `scripts/bundle.sh` uses it when present and falls back to an ad-hoc signature when not.
4. `./scripts/bundle.sh`, then `open dist/Hoboshell.app`.
5. Grant, when asked: Accessibility (window list, switcher, snapping), Screen Recording (live window pictures), and optionally Full Disk Access (browsing the Trash and other protected folders).
6. Optional: right-click the taskbar and tick "Replace the Mac Dock and desktop icons". The Dock restarts while its thickness is measured.

## Checking work

- `./scripts/test.sh` - unit tests, including speed tests.
- `./scripts/selftest.sh REPORT_FILE` - starts a probe app and times how fast the taskbar and tray follow its windows. Quit a running Hoboshell first. Last run: 9 of 9 steps passed, every instant step under 60 ms against a 150 ms budget.
- `./scripts/capture.sh FOLDER` - saves a picture of each Hoboshell window. The terminal needs Screen Recording.
- `open -g dist/Hoboshell.app --args --show start` (also `start=all`, `start=search:TEXT`, `files`, `files=PATH`, `switcher`, `tray=apps|volume|calendar|battery|network`) opens a surface and keeps it open without taking keyboard focus. Relaunch normally afterwards.
- `Hoboshell --gallery` shows every design system component.
- `Hoboshell --perf-log` logs event-to-screen latency and main thread stalls. Read with `/usr/bin/log show --last 5m --predicate 'subsystem == "dev.hoboware.hoboshell"'`.

## What is confirmed and what is not

Confirmed by measurement or by looking at captures: the design system gallery, the taskbar and tray layout, the explorer's details and icons views, the Start menu's pinned view, the icon set in place, the Dock reserving exactly the taskbar's height, the bar's window level above the Dock, and the self-test timings.

Not yet confirmed on screen by anyone: the switcher's look and the Command+Tab takeover, tray popups, grouping and pin reordering on the taskbar, Start menu search and keyboard use, explorer rename and sorting after the polish, the desktop-switch fix (bar staying put, buttons changing once), preview pictures for every app, the top bar with side dock look as a whole.

## Next, in order

1. **Realtime pass 2** (not started in code): explorer, Start menu, desktop icons and tray popups to the same standard as the bars. Folder listing off the main thread with the first rows inside 50 ms for 50,000 files; live add, remove and rename by diff instead of reloading; search on every keystroke; icon and thumbnail caches; an app index for instant Start search; popups that update in place and follow system notifications instead of timers; new self-test steps and a check that nothing stalls the main thread for over 100 ms.
2. **Protected folders in the explorer**: opening the Trash without Full Disk Access shows a raw error line. Replace it with a proper state that explains and offers "Open Full Disk Access settings" and "Open in Finder". Later: Restore and Empty Trash.
3. **Default file manager switch**: an option that makes "show in folder" from other apps open the Hoboshell explorer, saved and restored like the Dock settings.
4. **Windows phase**: drag-to-edge snapping with an outline, quarters, snap assist, window shortcuts.
5. **Explorer parity**: address bar menus and auto-complete, deep search, pinning and a folder tree, column choice, copy progress and a clash dialog, undo, properties, tabs, archives.
6. **Top bar with side dock look**: its own theme, dock pins and cards, app grid, overview, header-bar explorer.
7. **Release**: auto-update, a settings window, the project card on the Hoboware site.

## Known rough spots

- The Files icon looks smaller than the Start logo because its drawing has empty space around it.
- Icons view rows are tall when names fit on one line; the details view shows no thumbnails.
- Right after launch, an app whose windows are all on a desktop not yet visited can show as running in the background.
- Unread badges are read once a second; macOS offers no change notification for them.
- The top bar itself still overlaps windows in the top bar look; only the side dock reserves space.
- If the saved "original" Dock settings look wrong after turning the Dock option off, set the Dock as wanted in System Settings; the next time the option is turned on it saves the current values.
