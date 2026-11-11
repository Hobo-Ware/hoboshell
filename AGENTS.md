# Hoboshell - agent and contributor rules

Hoboshell is a Windows-style desktop shell for macOS: a taskbar, Start menu,
desktop and file explorer drawn as overlay windows on top of the normal Mac
desktop. It uses public macOS APIs only. Never ask the user to turn off System
Integrity Protection, and never use private frameworks.

## Layout

| Path | What lives there |
| --- | --- |
| `Sources/HoboshellCore` | Logic with no windows: geometry, file listing, filtering. No AppKit views. Everything here is unit tested. |
| `Sources/Hoboshell` | The app: windows, panels, system calls (Accessibility, NSWorkspace, `defaults`). |
| `Tests/HoboshellCoreTests` | Swift Testing suites for `HoboshellCore`. |
| `Support/Info.plist` | Keys for the packaged `.app` (`LSUIElement`, folder access texts). |
| `scripts/test.sh` | The one way to run tests. Works with or without full Xcode. |
| `scripts/bundle.sh` | Builds a signed `dist/Hoboshell.app`. Signs with the local certificate named `Hoboshell Dev` when the keychain has one, so macOS permissions survive rebuilds; otherwise ad-hoc. Delete `dist/` when you are done with it. |
| `scripts/capture.sh` | Saves a picture of each Hoboshell window that is on screen into a folder, for checking work by eye. Captures Hoboshell's own windows only. |
| `.github/workflows/ci.yml` | Build and test check. Runs on macOS, which is billed at a higher rate on a private repo, so it skips draft pull requests. |
| `CHANGELOG.md` | Record of work, newest first. |

## Commands

```sh
swift build            # compile
./scripts/test.sh      # run all tests
swift run              # launch the shell (shows a taskbar on your screen)
swift run Hoboshell --restore   # put Dock and Finder settings back
```

Run `swift build` and `./scripts/test.sh` before every commit. Report the test
count from the line `Test run with N tests ... passed`.

Do not use plain `swift test` on a machine with only the Command Line Tools:
it fails with `no such module 'Testing'`. The script adds the framework paths.

## Writing Swift here

- **Logic goes in `HoboshellCore`, views go in `Hoboshell`.** If a function
  can be written without a window, a screen or a running app, it belongs in
  Core and takes plain values (`CGRect`, `URL`, `String`). The app layer reads
  the live values (`NSScreen`, `NSWorkspace`) and passes them in.
- **One type per file**, file named after the type. Small helper types used by
  one type only may share its file.
- `final class` for every class. `enum` with static functions for namespaces
  that hold no state. `struct` for data.
- `private` by default. `public` only on what `Hoboshell` or the tests need
  from Core.
- No force unwraps and no `try!`. `as!` is allowed only right after a
  `CFGetTypeID` check on a Core Foundation value.
- `guard` for early exits. No nested `if let` ladders.
- Closures that are stored (callbacks, timers, observers) capture
  `[weak self]`.
- Errors a user can hit (a folder that cannot be read, a rename that fails)
  are shown in the window, never swallowed and never a crash.
- Constants get a name (`static let barHeight`), not a bare number repeated in
  two places.
- No comments, except for behaviour forced by macOS that the code cannot show
  (one or two lines, say what the system does).
- Swift language mode 5, deployment target macOS 13. Do not raise either
  without asking.

## System safety

- Anything that changes the user's Mac settings (Dock, Finder, `defaults`)
  must be off by default, must save the old value first, and must have an undo
  path that works after a crash (`--restore`).
- Never run `swift run` with `HOBOSHELL_HIDE_SYSTEM_UI=1` from an agent
  session. That is for the owner to try by hand.
- Never run `killall` on anything except through `SystemChrome`.
- File actions that remove things use the Trash (`trashItem`), never a hard
  delete.

## Testing rules

- Framework: **Swift Testing** (`import Testing`, `@Suite`, `@Test`,
  `#expect`). No XCTest.
- Every new function in `HoboshellCore` ships with tests in the same change.
- Name a test after the behaviour, as a sentence:
  `leftHalfStopsAboveTheTaskbar`, not `testSnap1`.
- One behaviour per test. Compare whole values (`#expect(frame == CGRect(...))`),
  not one field at a time.
- Cover the edges, not just the easy case: empty input, a second screen, a
  hidden file, an app bundle, a missing folder.
- Tests that touch the disk create their own folder under
  `FileManager.default.temporaryDirectory` and remove it in a `defer`. Never
  read or write the real home folder.
- Tests never open a window, never call the Accessibility API and never run
  `defaults`. If code needs one of those to be tested, split it: move the
  decision into Core and leave only the system call in the app.
- A bug fix starts with a test that fails without the fix.
- UI behaviour that cannot be unit tested goes under "Not verified" in the
  change description until someone has run the app and looked.

## Record of work

- Add a line to `CHANGELOG.md` under `Unreleased` in the same commit as the
  change. Say what a user would notice, not which file moved.
- Commit messages: `type: summary` (`feat`, `fix`, `refactor`, `test`,
  `docs`, `chore`). Plain hyphens only.
- Work on a branch and open a pull request. Do not push to `main`.
- Open pull requests as drafts and keep them drafts while you are still
  pushing fixes. Mark one ready only when it is done: that is what starts the
  check.

## Naming and branding

No Microsoft or Canonical names, logos, icons or artwork anywhere in the code,
the docs or the app. Describe looks in plain words ("bottom taskbar",
"top bar with a side dock").
