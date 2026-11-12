import CoreGraphics

public struct TaskbarButtonSpec: Equatable {
    public let id: String
    public let appID: String
    public let pid: Int32?
    public let name: String
    public let title: String
    public let windowIDs: [Int]
    public let isPinned: Bool
    public let isRunning: Bool
    public let isActive: Bool
    public let isBackground: Bool
    public let badge: String?

    public var isGroup: Bool { windowIDs.count > 1 }
    public var isIconOnly: Bool { windowIDs.isEmpty }
}

public enum TaskbarModel {
    public static func make(
        _ state: ShellState,
        grouping: TaskbarGrouping,
        availableWidth: CGFloat,
        spacing: CGFloat
    ) -> [TaskbarButtonSpec] {
        let appsByPID = Dictionary(state.apps.map { ($0.pid, $0) }, uniquingKeysWith: { first, _ in first })
        let visible = state.visibleWindows.filter { appsByPID[$0.pid] != nil }
        let regular = state.apps.filter { $0.policy == .regular }
        let runningApps = Set(regular.map(\.appID))
        let slots = TaskbarSlots.arrange(
            pins: state.pins,
            windowApps: visible.map { appsByPID[$0.pid]?.appID ?? "" },
            runningApps: runningApps,
            grouping: grouping,
            availableWidth: availableWidth,
            spacing: spacing
        )
        let appsByID = Dictionary(regular.map { ($0.appID, $0) }, uniquingKeysWith: { first, _ in first })
        let windowless = TrayModel.windowlessAppIDs(state)
        return slots.map { slot in
            let windows = slot.windows.map { visible[$0] }
            let app = windows.first.flatMap { appsByPID[$0.pid] } ?? appsByID[slot.appID]
            let isActive = windows.isEmpty
                ? app?.isActive ?? false
                : windows.contains { window in window.isFocused && appsByPID[window.pid]?.isActive == true }
            return TaskbarButtonSpec(
                id: windows.count == 1 ? "w\(windows[0].id)" : "a:\(slot.appID)",
                appID: slot.appID,
                pid: app?.pid,
                name: app?.name ?? windows.first?.title ?? "",
                title: windows.count == 1 ? windows[0].title : app?.name ?? "",
                windowIDs: windows.map(\.id),
                isPinned: slot.isPinned,
                isRunning: slot.isRunning,
                isActive: isActive,
                isBackground: windows.isEmpty && windowless.contains(slot.appID),
                badge: slot.isRunning ? state.badges[slot.appID] : nil
            )
        }
    }
}
