# Changelog

Record of work, newest first. Each entry says what a user would notice.

## Unreleased

### Added
- File explorer window: sidebar with common folders and drives, back, forward
  and up, an editable path bar, a details list and an icon grid, with Open,
  Rename, Move to Trash and New folder.
- File explorer button on the taskbar. Folders on the desktop now open in the
  file explorer.
- Unit tests for window snap geometry and folder listing (8 tests), and
  `scripts/test.sh` to run them with or without full Xcode.
- Repository rules (`AGENTS.md`), this changelog and a README.

### Changed
- Split the code into `HoboshellCore` (logic, tested) and `Hoboshell` (the app).

### Not verified
- The interface has not been checked on a live run: taskbar, Start menu,
  desktop, file explorer, snapping, and hiding and restoring the Dock.

## 0.1.0 - first commit

### Added
- Bottom taskbar on every desktop with a Start button, running app buttons,
  snap buttons and a clock.
- Start menu with app search.
- Desktop window with an icon grid of the Desktop folder.
- Window snapping to the left half, right half or full area.
- Optional hiding of the real Dock and desktop icons, off by default, with
  `--restore` to undo it.
