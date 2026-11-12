public struct SwitcherEntry: Equatable {
    public let windowID: Int
    public let pid: Int32
    public let title: String
    public let isMinimized: Bool
}

public enum SwitcherModel {
    public static func entries(_ state: ShellState) -> [SwitcherEntry] {
        let visible = state.visibleWindows.filter { window in state.apps.contains { $0.pid == window.pid } }
        let byID = Dictionary(visible.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return state.recency.ordered(visible.map(\.id)).compactMap { id in
            byID[id].map { SwitcherEntry(windowID: id, pid: $0.pid, title: $0.title, isMinimized: $0.isMinimized) }
        }
    }
}
