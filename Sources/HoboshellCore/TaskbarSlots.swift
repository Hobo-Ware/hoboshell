import CoreGraphics

public struct TaskbarSlot: Equatable {
    public let appID: String
    public let windows: [Int]
    public let isPinned: Bool
    public let isRunning: Bool

    public var isGroup: Bool { windows.count > 1 }
}

public enum TaskbarSlots {
    public static func arrange(
        pins: TaskbarPins,
        windowApps: [String],
        runningApps: Set<String>,
        grouping: TaskbarGrouping,
        availableWidth: CGFloat,
        spacing: CGFloat
    ) -> [TaskbarSlot] {
        var windowsByApp: [String: [Int]] = [:]
        var appOrder: [String] = []
        for (index, app) in windowApps.enumerated() {
            if windowsByApp[app] == nil {
                appOrder.append(app)
            }
            windowsByApp[app, default: []].append(index)
        }
        let apps = pins.ids + appOrder.filter { !pins.contains($0) }
        let ungroupedCount = apps.reduce(0) { $0 + max(windowsByApp[$1]?.count ?? 0, 1) }
        let folds = shouldFold(grouping, buttonCount: ungroupedCount, availableWidth: availableWidth, spacing: spacing)

        return apps.flatMap { app -> [TaskbarSlot] in
            let windows = windowsByApp[app] ?? []
            let isRunning = !windows.isEmpty || runningApps.contains(app)
            let isPinned = pins.contains(app)
            let groups: [[Int]] = folds || windows.isEmpty ? [windows] : windows.map { [$0] }
            return groups.map { TaskbarSlot(appID: app, windows: $0, isPinned: isPinned, isRunning: isRunning) }
        }
    }

    private static func shouldFold(
        _ grouping: TaskbarGrouping,
        buttonCount: Int,
        availableWidth: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        switch grouping {
        case .never: return false
        case .always: return true
        case .whenFull:
            let width = TaskbarLayout.buttonWidth(buttonCount: buttonCount, availableWidth: availableWidth, spacing: spacing)
            return !TaskbarLayout.showsTitle(atWidth: width)
        }
    }
}
