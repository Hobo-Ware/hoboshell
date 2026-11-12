import AppKit
import HoboshellCore

enum TaskbarActions {
    static func window(_ id: Int, in state: ShellState) -> ShellWindow? {
        guard let window = state.window(id: id), let app = state.app(pid: window.pid),
              let running = NSRunningApplication(processIdentifier: window.pid) else { return nil }
        return ShellWindow(
            id: id, app: running, title: window.title, isMinimized: window.isMinimized, isFocused: window.isFocused && app.isActive
        )
    }

    static func click(_ spec: TaskbarButtonSpec, in state: ShellState) {
        if let id = spec.windowIDs.first, let window = window(id, in: state) {
            toggle(window)
            return
        }
        guard spec.isRunning else {
            AppIcons.shared.launch(bundleID: spec.appID)
            return
        }
        guard let app = spec.pid.flatMap(NSRunningApplication.init(processIdentifier:)) else { return }
        if app.isActive {
            app.hide()
        } else {
            reveal(app)
        }
    }

    static func reveal(_ spec: TaskbarButtonSpec, in state: ShellState) {
        let target = spec.windowIDs.first { state.window(id: $0)?.isFocused == true } ?? spec.windowIDs.first
        if let target, let window = window(target, in: state) {
            WindowCatalog.shared.focus(window)
        }
    }

    static func close(_ spec: TaskbarButtonSpec, in state: ShellState) {
        spec.windowIDs.compactMap { window($0, in: state) }.forEach(WindowCatalog.shared.close)
    }

    static func quit(_ spec: TaskbarButtonSpec) {
        spec.pid.flatMap(NSRunningApplication.init(processIdentifier:))?.terminate()
    }

    static func items(for spec: TaskbarButtonSpec, in state: ShellState) -> [TaskbarItem] {
        spec.windowIDs.compactMap { id in
            guard let window = window(id, in: state), let app = state.app(pid: window.app.processIdentifier) else { return nil }
            var item = TaskbarItem(
                icon: AppIcons.shared.image(forPath: app.bundlePath),
                title: window.title,
                isActive: window.isFocused
            ) {
                toggle(window)
            }
            let request = PreviewRequest(
                windowID: id, pid: app.pid, title: window.title, isMinimized: window.isMinimized
            )
            item.preview = { limit, completion in
                WindowPreview.capture(request, limit: limit, completion: completion)
            }
            item.windowID = id
            item.close = { WindowCatalog.shared.close(window) }
            item.quit = { window.app.terminate() }
            item.appName = app.name
            item.appID = app.appID
            item.reveal = { WindowCatalog.shared.focus(window) }
            return item
        }
    }

    private static func toggle(_ window: ShellWindow) {
        if window.isFocused {
            WindowCatalog.shared.minimize(window)
        } else {
            WindowCatalog.shared.focus(window)
        }
    }

    private static func reveal(_ app: NSRunningApplication) {
        app.unhide()
        app.activate()
    }
}
