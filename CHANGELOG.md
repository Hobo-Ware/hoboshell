# Changelog

Record of work, newest first. Each entry says what a user would notice.

## Unreleased

### Added
- Apps that are running with no window (for example Slack after you press the
  red button) now show as small icons at the left end of the tray, with their
  unread count on the icon. Click one to bring its window back, right-click for
  Open and Quit. With more than three, an arrow opens a "Running in the
  background" list. A pinned app that runs with no window gets a small dot under
  its taskbar button instead of the line. `--show tray=apps` opens the list for
  screenshots (with sample rows when nothing is in the background), and the
  `--gallery` window shows the tray icon, its badge and the dot.
- "Replace the Mac Dock and desktop icons" (the old "Hide the Mac Dock" item,
  same setting) now keeps the real Dock on screen under the bar, the same
  thickness and never hidden, and draws the bar on top of it. Maximised and
  tiled windows now stop at the bar instead of sliding under it. The first
  run measures the Dock and adjusts its icon size to fit, so the Dock restarts
  a few times once; later runs restart it once. Switching between the two
  looks moves the Dock to the other edge. Your old Dock and Finder settings
  are saved first and put back when you turn it off, quit, or run
  `swift run Hoboshell --restore`; leftovers from a crash are put back at the
  next start.
- "Keep windows above the taskbar" in the bar's right-click menu, on by
  default: a window whose bottom edge ends up under the bottom taskbar gets
  shorter so it sits just above it.
- A new window switcher on Command+Tab and Command+Shift+Tab (Option+Tab still
  works). It shows one tile per window with a live picture, the app icon and
  the title, most recently used first, and wraps onto more rows when needed.
  Hold Command and press Tab or Shift+Tab to move, use the arrow keys to move
  in the grid, release Command to switch, press Escape to cancel, Q to quit
  the highlighted app, W to close its window, or click a tile. A quick press
  and release switches to the previous window. Turn it off with "Use Hoboshell
  for Command+Tab" in the bar's right-click menu to get the Mac switcher back.
- `--show switcher` opens the switcher for screenshots, and the `--gallery`
  window shows the switcher tile.
- The explorer remembers whether you last used the details or the icons view.
- The Start menu is now a full flyout. A grid of pinned apps (Safari, Mail,
  Calendar, Notes, Music, Photos, System Settings and Terminal to begin with)
  drags to reorder and remembers its order. "All apps" lists every app A to Z
  with letter headers, and up to six recent files sit under the pins.
- Start menu search covers apps, files and Settings panes in grouped results.
  Type anywhere to search, use the arrow keys to move, and press Enter to open
  the highlighted result (the top hit by default).
- The Start menu has a left rail (Home, Documents, Downloads, Pictures and
  Settings), your name and picture with Lock screen and Sign out, and a power
  button with Sleep, Restart and Shut down. macOS asks before it restarts,
  shuts down or signs you out.
- Right-click an app in the Start menu for Open, Pin to Start or Unpin from
  Start, Pin to taskbar or Unpin from taskbar, and Show in Files.
- Option+Space opens and closes the Start menu. Tab moves between the search
  field, the rail, the apps and the footer. Escape, a click outside, or
  switching to another app closes it.
- `--show start=all` and `--show start=search:TEXT` open the Start menu on the
  All apps view or on search results.
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
- Taskbar running marks are easier to see: a 12 wide white line under running
  apps and a 20 wide accent line under the focused window, both a little
  thicker. The Start logo and the Files bindle are drawn at 32 pt instead of
  being squeezed into 24.
- The explorer's Icons view is redrawn: bigger 96 pt pictures, names up to two
  lines that shorten in the middle, a hairline frame around real photo and
  video thumbnails, an accent-tinted tile when selected with the name on an
  accent pill, and an even grid. Renaming in place shows a text field exactly
  as wide as the tile and the tile no longer changes height.
- The explorer's Details view has quieter column titles lined up with the
  text beneath them (Size lines up with the sizes) under a hairline, with the
  sort arrow beside the title. Rows are 28 high with 20 pt icons, dates follow
  your region's format (medium date, short time), and the selected row and the
  current place in the side pane share the accent-tinted highlight. Side pane
  rows are 28 high with section titles in small dim text, and the status bar
  has more breathing room.
- The explorer's two toolbar rows are redone. The address bar shows the
  current folder's icon and clickable path chips separated by arrows; paths
  inside your home folder start at Home instead of Computer > Users > name,
  and when the path is too long the leftmost folders fold into a "..." menu.
  Command+L or a click on empty space still lets you type a path. Search is a
  rounded field with a clear button, and the command row uses one icon weight,
  a Rename pencil, a Sort menu button with an arrow, and a Details / Icons
  switch and hidden-files toggle that light up in the accent colour.
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
- The Start menu header lines up: "Pinned" and "All apps >" sit on one row
  with the control at the right end and a small arrow, and the Back row of the
  All apps list is centred the same way. A tooltip with your name no longer
  pops up over other parts of the menu.
- App icons in the Start menu and on the taskbar no longer pop in late. They
  are kept in memory, and the pinned and installed apps are loaded in the
  background when Hoboshell starts.
- A taskbar button no longer vanishes and comes back while its window
  minimises. A window stays listed until its app quits, the window is closed,
  or it has been missing from two reads half a second apart.
- Hovering a taskbar button now shows a window picture for apps like Chrome
  that showed only an icon before. The picture is found among all of the app's
  windows (other Spaces and full screen included), by position, then by title,
  then as the app's only window. A minimised window shows its last picture.
  The reason for any miss is written to the system log once.
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
