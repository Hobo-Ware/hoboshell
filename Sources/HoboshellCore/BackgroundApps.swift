public enum BackgroundApps {
    public static let inlineLimit = 3

    public static func trayIDs(windowless: [String], pinned: TaskbarPins, excluded: Set<String>) -> [String] {
        var seen = Set<String>()
        return windowless.filter { !pinned.contains($0) && !excluded.contains($0) && seen.insert($0).inserted }
    }

    public static func split<Item>(_ items: [Item]) -> (inline: [Item], opensFlyout: Bool) {
        (Array(items.prefix(inlineLimit)), items.count > inlineLimit)
    }
}
