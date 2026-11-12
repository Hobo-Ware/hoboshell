public struct ShellState: Equatable {
    public private(set) var apps: [ShellApp] = []
    public private(set) var windows: [WindowState] = []
    public private(set) var pins = TaskbarPins()
    public private(set) var badges: [String: String] = [:]
    public private(set) var recency = WindowRecency()

    public init() {}

    public init(pins: TaskbarPins) {
        self.pins = pins
    }

    public func app(pid: Int32) -> ShellApp? {
        apps.first { $0.pid == pid }
    }

    public func window(id: Int) -> WindowState? {
        windows.first { $0.id == id }
    }

    public var visibleWindows: [WindowState] {
        windows.filter(\.isOnThisDesktop)
    }

    @discardableResult
    public mutating func apply(_ event: ShellEvent) -> ShellChange {
        var change = ShellChange()
        switch event.kind {
        case .appLaunched(let app):
            launch(app, into: &change)
        case .appTerminated(let pid):
            terminate(pid, into: &change)
        case .appActivated(let pid):
            activate(pid, into: &change)
        case .appHidden(let pid):
            setHidden(true, pid: pid, into: &change)
        case .appUnhidden(let pid):
            setHidden(false, pid: pid, into: &change)
        case .appsRead(let read):
            reconcile(apps: read, into: &change)
        case .windowCreated(let window):
            create(window, into: &change)
        case .windowDestroyed(let id):
            destroy(id, into: &change)
        case .windowTitleChanged(let id, let title):
            edit(id, into: &change) { $0.title = title }
        case .windowMinimized(let id):
            edit(id, into: &change) { $0.isMinimized = true }
        case .windowRestored(let id):
            edit(id, into: &change) { $0.isMinimized = false }
        case .windowFocused(let id):
            focus(id, into: &change)
        case .appSnapshot(let pid, let snapshot, let reason):
            read(snapshot, of: pid, because: reason, into: &change)
        case .desktopChanged:
            change.desktopChanged = true
        case .badgesRead(let read):
            guard read != badges else { break }
            badges = read
            change.badgesChanged = true
        case .pinsChanged(let next):
            guard next != pins else { break }
            pins = next
            change.pinsChanged = true
        }
        return change
    }

    private func appIndex(_ pid: Int32) -> Int? {
        apps.firstIndex { $0.pid == pid }
    }

    private func windowIndex(_ id: Int) -> Int? {
        windows.firstIndex { $0.id == id }
    }

    private mutating func launch(_ app: ShellApp, into change: inout ShellChange) {
        if let index = appIndex(app.pid) {
            var merged = app
            merged.hasReadWindows = apps[index].hasReadWindows
            if merged != apps[index] {
                apps[index] = merged
                change.changed(app: app.pid)
            }
        } else {
            apps.append(app)
            change.added(app: app.pid)
        }
        if app.isActive {
            makeActive(app.pid, into: &change)
        }
    }

    private mutating func terminate(_ pid: Int32, into change: inout ShellChange) {
        guard let index = appIndex(pid) else { return }
        apps.remove(at: index)
        change.removed(app: pid)
        for window in windows where window.pid == pid {
            recency.forget(window.id)
            change.removed(window: window.id)
        }
        windows.removeAll { $0.pid == pid }
    }

    private mutating func activate(_ pid: Int32, into change: inout ShellChange) {
        guard let index = appIndex(pid) else { return }
        if apps[index].isHidden {
            apps[index].isHidden = false
            change.changed(app: pid)
        }
        makeActive(pid, into: &change)
    }

    private mutating func makeActive(_ pid: Int32, into change: inout ShellChange) {
        for index in apps.indices where apps[index].isActive != (apps[index].pid == pid) {
            apps[index].isActive.toggle()
            change.changed(app: apps[index].pid)
        }
        touchRecency(of: pid, into: &change)
    }

    private mutating func setHidden(_ hidden: Bool, pid: Int32, into change: inout ShellChange) {
        guard let index = appIndex(pid), apps[index].isHidden != hidden else { return }
        apps[index].isHidden = hidden
        change.changed(app: pid)
    }

    private mutating func reconcile(apps read: [ShellApp], into change: inout ShellChange) {
        let readPIDs = Set(read.map(\.pid))
        for pid in apps.map(\.pid) where !readPIDs.contains(pid) {
            terminate(pid, into: &change)
            change.drift.append("app \(pid) is gone but was still in the model")
        }
        for app in read {
            guard let index = appIndex(app.pid) else {
                launch(app, into: &change)
                change.drift.append("app \(app.name) (\(app.pid)) was running but not in the model")
                continue
            }
            let known = apps[index]
            if known.isHidden != app.isHidden || known.isActive != app.isActive {
                change.drift.append("app \(app.name) (\(app.pid)) had a different hidden or active state")
            }
            var merged = app
            merged.hasReadWindows = known.hasReadWindows
            if merged != known {
                apps[index] = merged
                change.changed(app: app.pid)
            }
            if app.isActive {
                makeActive(app.pid, into: &change)
            }
        }
    }

    private mutating func create(_ window: WindowState, into change: inout ShellChange) {
        guard appIndex(window.pid) != nil else { return }
        guard let index = windowIndex(window.id) else {
            windows.append(window)
            change.added(window: window.id)
            if window.isFocused {
                clearFocus(except: window.id, pid: window.pid, into: &change)
                touchRecency(of: window.pid, into: &change)
            }
            return
        }
        if windows[index] != window {
            windows[index] = window
            change.changed(window: window.id)
        }
    }

    private mutating func destroy(_ id: Int, into change: inout ShellChange) {
        guard let index = windowIndex(id) else { return }
        windows.remove(at: index)
        recency.forget(id)
        change.removed(window: id)
    }

    private mutating func edit(_ id: Int, into change: inout ShellChange, _ body: (inout WindowState) -> Void) {
        guard let index = windowIndex(id) else { return }
        var edited = windows[index]
        body(&edited)
        guard edited != windows[index] else { return }
        windows[index] = edited
        change.changed(window: id)
    }

    private mutating func focus(_ id: Int, into change: inout ShellChange) {
        guard let index = windowIndex(id) else { return }
        let pid = windows[index].pid
        if !windows[index].isFocused {
            windows[index].isFocused = true
            change.changed(window: id)
        }
        clearFocus(except: id, pid: pid, into: &change)
        touchRecency(of: pid, into: &change)
    }

    private mutating func clearFocus(except id: Int, pid: Int32, into change: inout ShellChange) {
        for index in windows.indices where windows[index].pid == pid && windows[index].id != id && windows[index].isFocused {
            windows[index].isFocused = false
            change.changed(window: windows[index].id)
        }
    }

    private mutating func touchRecency(of pid: Int32, into change: inout ShellChange) {
        guard let app = app(pid: pid), app.isActive,
              let focused = windows.first(where: { $0.pid == pid && $0.isFocused && $0.isOnThisDesktop }),
              recency.mostRecent != focused.id else { return }
        recency.activated(focused.id)
        change.recencyChanged = true
    }

    private mutating func read(
        _ snapshot: [WindowState],
        of pid: Int32,
        because reason: ShellEvent.SnapshotReason,
        into change: inout ShellChange
    ) {
        guard let appAt = appIndex(pid) else { return }
        let isSweep = reason == .sweep
        if !apps[appAt].hasReadWindows {
            apps[appAt].hasReadWindows = true
            change.changed(app: pid)
        }
        var seen = Set<Int>()
        for var incoming in snapshot where incoming.pid == pid {
            seen.insert(incoming.id)
            incoming.isOnThisDesktop = true
            if let index = windowIndex(incoming.id) {
                guard windows[index] != incoming else { continue }
                if isSweep {
                    change.drift.append("window \(incoming.id) of \(pid) differed: \(windows[index].title) -> \(incoming.title)")
                }
                windows[index] = incoming
                change.changed(window: incoming.id)
            } else {
                windows.append(incoming)
                change.added(window: incoming.id)
                if isSweep {
                    change.drift.append("window \(incoming.id) of \(pid) (\(incoming.title)) was missing from the model")
                }
            }
        }
        for window in windows where window.pid == pid && window.isOnThisDesktop && !seen.contains(window.id) {
            if reason == .desktopChange {
                edit(window.id, into: &change) { $0.isOnThisDesktop = false }
                continue
            }
            if isSweep {
                change.drift.append("window \(window.id) of \(pid) (\(window.title)) was gone but still in the model")
            }
            destroy(window.id, into: &change)
        }
        touchRecency(of: pid, into: &change)
    }
}
