# Changelog

Record of work, newest first. Each entry says what a user would notice.

## Unreleased

### Added
- Hoboshell's own icon set, drawn in a hobo theme: a bindle for Files, taped
  cardboard folders with stitched patches for places, a cardboard shelter for
  Home, a tin can for drives, a rusty barrel for the Trash that burns when it
  holds something, and an app icon made from the Hoboware logo.
- The taskbar can pin apps. Right-click a button and pick "Pin to taskbar"
  (or "Unpin from taskbar"). Pinned apps stay on the bar as an icon when they
  are not running, open on a click, come first, and drag sideways to reorder;
  the order is remembered.
- Taskbar buttons show a short line under running apps and a wider accent
  line under the focused window.
- Windows of one app can fold into a single button with a count. Right-click
  an empty part of the bar and pick "Group windows": Never, When the taskbar
  is full (the default) or Always. Clicking a grouped button opens a strip of
  preview cards, one per window with its own live picture, title and close
  button, and the strip scrolls sideways when there are many.
- Right-click a taskbar button for Close window, Close all windows (groups),
  Quit, Pin or Unpin, and Open for a pinned app that is not running.
- When the buttons no longer fit even as icons, small arrows at each end of
  the strip page through them.
- Holding a dragged file over a taskbar button for a moment brings that
  window forward so you can drop the file into it.
- Clicking the show desktop strip hides every app; clicking it again brings
  back exactly the apps that were showing before. Activating any app yourself
  starts over.
- A taskbar button shows its app's Dock badge (for example an unread count)
  as a small red label. It needs Accessibility access and shows nothing
  without it.
- `Hoboshell --show start` opens the shell with the Start menu open, and
  `--show files` or `--show files=/some/path` opens a file explorer window on
  the home folder or that folder. Handy for screenshots.
- `Hoboshell --gallery` also shows the running and active marks, the group
  count and the unread badge.

### Changed
- Every screen now uses one shared set of sizes, spacing and colours, so the
  taskbar, tray, Start menu, preview cards, window switcher, desktop icons,
  top bar, side dock and file explorer line up: toolbars have the same height
  and padding, buttons share heights, tray items hug their content, and every
  button shows a pressed look. `Hoboshell --gallery` opens one window that
  shows every component in every state.
- The file explorer is rebuilt as a two-pane explorer. It has a clickable
  path bar (Command+L to type a path), a search box, Back / Forward / Up /
  Refresh, and a command row with New folder, Cut, Copy, Paste, Rename, Move
  to Trash, Sort, a Details / Icons switch and a hidden-files toggle. The
  side pane lists Quick access, Drives and Trash, and drives appear and
  disappear as you mount and eject them. Details view sorts by clicking a
  column header. Items rename in place (F2 or a slow second click), open with
  Enter, go up with Backspace, preview with Space, and select by typing a
  name. Copy and Cut share the Mac clipboard with Finder, a paste never
  overwrites ("name copy"), and files can be dragged out to other apps and
  onto folders. The status bar shows the item count and the selection size,
  and the folder refreshes by itself when it changes on disk. Every failure
  shows in the window.

### Fixed
- Desktop icons now react: they light up under the pointer, select on a
  click, open on a double click and have a right-click menu. Finder's own
  desktop was sitting on top and taking every click; it is now covered.
- A closed window leaves the taskbar right away instead of up to a second
  and a half later.
- Long names under desktop icons wrap onto two lines.
- Window buttons on the taskbar have padding inside, so the highlight on the
  selected one no longer hugs its icon.
- The system tray now sits at the right end of the taskbar.
  It was being pushed toward the middle.
- Snapping now also works for apps that report no focused window, and each
  attempt writes its result to the system log.

### Removed
- The three snap buttons on the taskbar. Snapping stays on the keyboard:
  Control+Option+Left, Right and Up.

### Added
- The explorer's icons view shows a small picture of each image, video and
  document instead of a generic file icon.
- Rest the pointer on a window's taskbar button to get a card with a live
  picture of the window, its title and a close button. Click the card to
  bring the window forward. The picture needs the Screen Recording
  permission; without it the card shows the app icon.
- Right-click a window's taskbar button to close the window or quit its app.
- Taskbar buttons, tray items and dock buttons light up under the pointer.
- Right-click a bar to hide the Mac Dock and Finder's desktop icons. The old
  settings come back when Hoboshell quits.
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
