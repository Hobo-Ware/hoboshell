# Changelog

Record of work, newest first. Each entry says what a user would notice.

## Unreleased

### Changed
- The file explorer remembers how you sorted it (column and direction) and
  whether hidden files are shown. New windows and restarts keep your choice.

## 0.2.11

### Fixed
- The taskbar no longer jumps back over a full-screen app, such as a video
  played full screen in a browser, a moment after it goes full screen. It
  hides while the app is full screen on its screen and comes back when you
  leave full screen. 0.2.10 did not fix this.

## 0.2.10

### Fixed
- The taskbar no longer covers full-screen apps, such as a video played
  full screen in a browser. It comes back when you leave full screen.

## 0.2.9

### Changed
- The Files button on the taskbar shows the peeking box instead of the red
  bindle. Finder uses the same icon.
- The Start menu sits on the same system glass as the taskbar on macOS 26
  and later. Older versions and Reduce Transparency keep the tinted surface.

## 0.2.8

### Changed
- Finder has its own Kraft box icon, a box with eyes peeking out, in the
  Start menu, on the taskbar and in the switcher.

## 0.2.7

### Changed
- The Start menu is see-through glass with a darker tint, so the desktop
  shows through while its text keeps the same tested contrast.
- Finder is pinned first in the Start menu, also for people who already
  have a saved pin list.
- With centred taskbar buttons, the taskbar shows app icons only, so the
  row sits evenly in the middle of the bar. Left-aligned buttons keep their
  window titles.

### Fixed
- A window preview with a long title stays centred over its taskbar
  button. The title is cut short instead of stretching the card.
- The taskbar Trash shows a full bin when it has items, even while macOS
  keeps the Trash private from Hoboshell.

### Added
- Right-click the taskbar Trash and choose "Empty Trash" to empty it.
  Hoboshell asks first, then asks Finder to do it.

## 0.2.6

### Fixed
- With "Replace the Mac Dock" on, the Mac Dock's app name labels no longer
  pop up above the taskbar. The Dock is now fully hidden instead of sitting
  under the bar, so a maximised window may reach under the bar for a moment
  before it shrinks above it.

## 0.2.5

### Fixed
- Opening the Trash no longer shows a permission error. When macOS keeps
  the Trash private from Hoboshell, it opens in Finder instead.

## 0.2.4

### Fixed
- The Trash icon sits in the middle of its button instead of low.

## 0.2.3

### Added
- A Trash button sits next to the tray on the taskbar. It shows a full bin
  when the Trash has items, opens the Trash in the file explorer on click, and
  moves files to the Trash when you drop them on it. Right-click offers
  "Open Trash".
- In the file explorer, Trash is now pinned under a divider at the bottom of
  the sidebar, and dropping files on it moves them to the Trash. Without Full
  Disk Access macOS hides the Trash contents, so the bin always looks empty.

### Changed
- All icons are now the Kraft box set: cardboard folders and places, a red
  bindle sack for Files, a cardboard TV, drive box, tin-can phone and gear.
  Small sizes use a simpler, bolder drawing so they stay readable.
- The taskbar now uses the system's own glass, like the menu bar and Dock, on
  macOS 26 and later, and a blurred menu-style backdrop on older versions. It
  stays solid while "Replace the Mac Dock" is on.

### Fixed
- With centred taskbar buttons, the Start menu opens in the middle of the
  screen instead of at the left edge.
- The file explorer no longer freezes while it reads a big folder or while
  paste, drop, trash and new folder do their file work. The window stays
  responsive and shows the result when it is ready.

### Removed
- The second look (top bar with a side dock) and its right-click switch entry
  and `--variant` flag are gone; Hoboshell always shows the bottom taskbar. A
  remembered choice of the old look is ignored, and the Mac Dock settings
  saved earlier still come back on quit or `--restore`.
- The "Folder style" menu and the four other icon styles. A saved folder
  style is ignored.

## 0.2.2

### Note
- Updates are signed with a new key, so 0.2.1 cannot update itself to this
  version. Download it once from the release page. macOS also asks for
  Accessibility again, because the signing certificate changed too.

### Fixed
- Centred taskbar buttons no longer drift right of centre when a button
  grows to show its window title.

### Changed
- Starting with `--perf-log` now also records how long file explorer actions
  (paste, drop, trash, new folder, folder reload) and the Start menu (opening,
  search results) take.

## 0.2.1

### Fixed
- With "Replace the Mac Dock and desktop icons" on, an app that parks its
  hidden window at the bottom edge of the screen could be hidden but not shown
  again. The taskbar and the cover over the Dock no longer block it.
- Hoboshell asks for Accessibility at most once each time it starts.
- Hovering a taskbar button no longer shows a tooltip on top of the preview
  card, and the volume slider no longer shows a second, system tooltip.

### Changed
- Releases are signed with one stable certificate, so macOS keeps the
  Accessibility permission across updates. Allow it once more after this
  update.

### Known limits
- While the overview opens, macOS draws the real Dock above everything for a
  moment. Once the overview is open the Dock is covered again.

## 0.2.0

### Changed
- The taskbar has a glass look with a thin line along its top edge. It turns
  solid when Reduce Transparency is on. Buttons show a plate on hover, a line
  under running apps that grows when the app gets focus, a stacked edge for
  grouped windows and a dip when pressed.
- Taskbar buttons are centred by default. The right-click menu has a **Taskbar
  alignment** setting to move them back to the left.
- The Wi-Fi, sound and battery icons now sit in one tray button with one hover
  plate. One click opens quick settings, and scrolling over it still changes
  the volume. Hover it for the network, volume and battery in one line.
- Quick settings shows three tiles per row with the name under each tile.
  Wi-Fi is a split tile: the icon turns Wi-Fi on or off and the arrow opens the
  Wi-Fi page. Sliders have ring handles. The battery in the footer opens the
  battery details.
- Tray popups rise from the bar and sink back when closed. Nothing moves when
  Reduce Motion is on.

### Added
- The tray icons follow what is happening: Wi-Fi strength in three steps, Wi-Fi
  on but not joined, Wi-Fi off, no internet (amber) and a cable. The battery
  turns green while charging, amber in Low Power Mode and red under 6 percent.
- The Wi-Fi page puts the joined network on top with "Connected, secured" or
  "Connected, open" and a **Disconnect** button. A refresh button looks for
  networks again, and Wi-Fi off, looking for networks and hidden network names
  each have their own screen.

### Fixed
- The Wi-Fi page no longer lists the joined network under "Other networks" with
  no current row when macOS does not give out its name.

## 0.1.3

### Fixed
- Hoboshell no longer hangs with nothing on screen while macOS asks for access
  to the Desktop folder. The bars show at once and the desktop icons appear
  when access is given. This hit every first start and every start after an
  update.
- Opening the Wi-Fi page, the list of sound outputs or the list of apps
  running in the background no longer crashes the shell. Each list tied a new
  row's width to the list before the row was in it.
- Hoboshell stops watching an app that has quit before it ever showed a
  window. A crash seen right after another app started and quit points here.

## 0.1.2

### Added
- Hoboshell now checks for new versions once a day and offers to install them.
  The taskbar's right-click menu shows the version, has **Check for
  updates...** and a tick to turn the daily check off.

## 0.1.1

### Fixed
- Popups are readable over any page, a white one included. Every flyout, the
  Start menu, the window previews and the window switcher now sit on a dark
  surface with a blur behind it, and dim text and the disabled look are
  brighter. Values such as the IP address, battery time and volume percent are
  in the normal text size.
- Hovering a tray app icon, a taskbar button, the clock or any other icon-only
  button now shows its name after half a second. macOS only draws its own
  tooltips for the active app, and Hoboshell never is, so the shell now draws
  them itself. Moving to the next button shows its tooltip at once.
- With the Mac Dock replaced, the real Dock no longer shows in the overview
  of all windows. A plain strip keeps it covered there.

### Added
- The network item opens a quick settings panel: tiles for Wi-Fi, Bluetooth,
  Low Power, Dark mode, Focus and the keyboard layout, a volume slider with a
  list of sound outputs, and a footer with the battery, your IP address and a
  gear for network settings. The Wi-Fi tile turns Wi-Fi on and off; its arrow
  opens a Wi-Fi page with the current network and the other networks nearby,
  strongest first. The Keyboard tile switches to the next input source. The
  other tiles open the matching page of System Settings, because macOS has no
  way to flip them from another app. Network names need the Location
  permission, which is asked for only when you open the Wi-Fi page.
- A drives item in the tray whenever an external or removable drive is
  connected. Click it to open a drive in the explorer or to eject it.

## 0.1.0

First release.

### Added
- Folder style: right-click a bar and pick how folders and places look. Tin
  folder (the new default), roped suitcase, bean can, patched sack or broken
  crate. Open windows and the desktop change at once.
- `scripts/selftest.sh` runs `Hoboshell --selftest realtime`: the shell opens
  a small helper app (`HoboshellProbe`) with plain windows that never take
  keyboard focus, opens, retitles, minimises, restores and closes them, and
  times how long the taskbar and tray take to show each change. Every step must
  show within 150 ms. `--selftest-report PATH` also writes the result to a file.
- Click the network icon in the tray for a flyout with connected or offline,
  Wi-Fi or wired, the local IP address and a "Network settings" button. It does
  not read the Wi-Fi name or scan. `--show tray=network` opens it for
  screenshots. Tray flyouts open one at a time and close on Escape, a click
  outside, or a second click on their item.
- Click the battery in the tray for a flyout with the charge, whether it is
  charging, plugged in or on battery, the time left or to full when the Mac
  reports it, whether Low Power Mode is on, and a "Battery settings" button.
  `--show tray=battery` opens it for screenshots. Macs without a battery still
  show no battery item.
- The tray clock now follows the Mac's region settings (12 or 24 hour, date
  order) instead of a fixed 24-hour pattern. Click it for a calendar flyout:
  today's date, a month grid with week numbers and today marked, previous and
  next month arrows, a "Today" button and a "Date and time settings" button.
  `--show tray=calendar` opens it for screenshots.
- A volume item in the tray that follows the level and mute state of the
  current output device. Scroll over it to change the volume in 5% steps; click
  it for a slider, a mute button, the list of outputs (click one to switch) and
  a "Sound settings" button. `--show tray=volume` opens it for screenshots.
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
- GPL v3.0 license. Hoboshell is open source, and versions built on it must
  stay open too.

### Changed
- The taskbar, the tray background list, the side dock and the Option+Tab
  switcher now follow windows and apps as they change instead of checking every
  second and a half. A new window, a closed window, a minimise, a restore, a new
  title or a quit shows up at once, and an app moves to the tray the moment its
  last window closes. Buttons are updated in place, so hover and pressed looks
  no longer reset and nothing flickers. Windows that are minimised never lose
  their button.
- Hover highlights appear instantly and fade out in 0.08 s. The window preview
  card opens after 0.3 s and shows the last picture of the window straight away
  while a fresh one loads.
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
- Restoring a minimised Hoboshell window (the file explorer, for example)
  from the taskbar no longer crashes the shell.
- The taskbar now draws above the Mac Dock. It was sitting below it, so the
  Dock showed on top of the bar whenever the Dock was visible.
- Switching desktops no longer makes the taskbar slide away with the desktop,
  and its buttons change once to the new desktop's windows instead of in
  several steps. An app whose windows are on another desktop is not shown as
  running in the background.
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
