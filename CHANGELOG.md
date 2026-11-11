# Changelog

Record of work, newest first. Each entry says what a user would notice.

## Unreleased

### Fixed
- Window buttons on the taskbar have padding inside, so the highlight on the
  selected one no longer hugs its icon.
- The system tray and snap buttons now sit at the right end of the taskbar.
  They were being pushed toward the middle.
- Snapping now also works for apps that report no focused window, and each
  attempt writes its result to the system log.

### Added
- The Start button now shows the official Hoboware logo: red cap, with the
  face in white so it reads on the dark taskbar.
- Clicking the network, battery or clock in the tray opens the matching page
  in System Settings.
- GitHub Actions check that builds the app and runs the tests on every pull
  request that is ready for review, and on every push to `main`.
- Second look: a slim top bar with an Activities button and the system tray,
  plus an icon dock down the left edge. Switch looks from the right-click menu
  on any bar, or start with `--variant top-bar-dock`. The choice is remembered.
- Window snapping and the desktop icon grid keep clear of whichever bars the
  current look shows.
- Taskbar shows one button per open window, with its title. Click to bring a
  window forward, click the active one to minimise it. Buttons shrink, then
  drop their titles, as the bar fills up.
- System tray on the right of the taskbar: network state, battery level, and a
  clock with the date.
- Show desktop strip at the far right edge of the taskbar.
- Window switcher: hold Option and press Tab to step through open windows,
  release Option to switch.
- Keyboard shortcuts for snapping: Control+Option+Left, Right and Up.
- Copy, paste, cut, undo and select all now work in the file explorer's text
  fields.
- `scripts/bundle.sh` builds a signed `dist/Hoboshell.app`.
- File explorer window: sidebar with common folders and drives, back, forward
  and up, an editable path bar, a details list and an icon grid, with Open,
  Rename, Move to Trash and New folder.
- File explorer button on the taskbar. Folders on the desktop now open in the
  file explorer.
- Unit tests for taskbar button sizing, switcher selection and battery
  display, and for the layout and choice of look (29 tests in total).
- Unit tests for window snap geometry and folder listing (8 tests), and
  `scripts/test.sh` to run them with or without full Xcode.
- Repository rules (`AGENTS.md`), this changelog and a README.

### Changed
- Split the code into `HoboshellCore` (logic, tested) and `Hoboshell` (the app).

### Not verified
- The interface has not been checked on a live run: taskbar, Start menu,
  desktop, file explorer, snapping, window buttons, system tray, window
  switcher, keyboard shortcuts, both looks and switching between them, and
  hiding and restoring the Dock.

## 0.1.0 - first commit

### Added
- Bottom taskbar on every desktop with a Start button, running app buttons,
  snap buttons and a clock.
- Start menu with app search.
- Desktop window with an icon grid of the Desktop folder.
- Window snapping to the left half, right half or full area.
- Optional hiding of the real Dock and desktop icons, off by default, with
  `--restore` to undo it.
