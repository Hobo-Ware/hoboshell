import CoreGraphics
@testable import HoboshellCore

enum Shell {
    static func app(_ pid: Int32, _ bundle: String? = nil, name: String? = nil, policy: ShellApp.Policy = .regular, active: Bool = false) -> ShellApp {
        ShellApp(pid: pid, bundleID: bundle ?? "app.\(pid)", name: name ?? "App\(pid)", policy: policy, isActive: active)
    }

    static func window(_ id: Int, _ pid: Int32, _ title: String? = nil, minimized: Bool = false, focused: Bool = false) -> WindowState {
        WindowState(id: id, pid: pid, title: title ?? "Window\(id)", isMinimized: minimized, isFocused: focused)
    }

    static func state(_ kinds: ShellEvent.Kind...) -> ShellState {
        var state = ShellState()
        for kind in kinds {
            state.apply(ShellEvent(kind))
        }
        return state
    }

    static func running(apps: [ShellApp], windows: [WindowState] = []) -> ShellState {
        var state = ShellState()
        for app in apps {
            state.apply(ShellEvent(.appLaunched(app)))
            let own = windows.filter { $0.pid == app.pid }
            state.apply(ShellEvent(.appSnapshot(pid: app.pid, windows: own, reason: .launch)))
        }
        return state
    }

    static func buttons(_ state: ShellState, grouping: TaskbarGrouping = .never, width: CGFloat = 1_200) -> [TaskbarButtonSpec] {
        TaskbarModel.make(state, grouping: grouping, availableWidth: width, spacing: 4)
    }
}
