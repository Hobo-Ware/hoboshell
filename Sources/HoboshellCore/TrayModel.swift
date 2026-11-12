public struct BackgroundEntry: Equatable {
    public let appID: String
    public let pid: Int32
    public let name: String
    public let badge: String?
}

public enum TrayModel {
    public static func windowlessAppIDs(_ state: ShellState) -> Set<String> {
        let withWindows = Set(state.windows.map(\.pid))
        return Set(state.apps.filter { $0.policy == .regular && $0.hasReadWindows && !withWindows.contains($0.pid) }.map(\.appID))
    }

    public static func backgroundApps(_ state: ShellState, excluded: Set<String>) -> [BackgroundEntry] {
        let withWindows = Set(state.windows.map(\.pid))
        let windowless = state.apps.filter { $0.policy == .regular && $0.hasReadWindows && !withWindows.contains($0.pid) }
        let ids = BackgroundApps.trayIDs(windowless: windowless.map(\.appID), pinned: state.pins, excluded: excluded)
        let byID = Dictionary(windowless.map { ($0.appID, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { id in
            byID[id].map { BackgroundEntry(appID: id, pid: $0.pid, name: $0.name, badge: state.badges[id]) }
        }
    }
}
