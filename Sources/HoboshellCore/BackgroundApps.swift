import Foundation

public struct BackgroundApps {
    public struct Candidate: Equatable {
        public let id: String
        public let pid: Int32
        public let windowCount: Int
        public let windowsReadable: Bool

        public init(id: String, pid: Int32, windowCount: Int, windowsReadable: Bool) {
            self.id = id
            self.pid = pid
            self.windowCount = windowCount
            self.windowsReadable = windowsReadable
        }
    }

    public static let settleDelay: TimeInterval = 2
    public static let inlineLimit = 3

    private var windowlessSince: [Int32: TimeInterval] = [:]

    public init() {}

    public mutating func settledWindowless(_ candidates: [Candidate], now: TimeInterval) -> [String] {
        var since: [Int32: TimeInterval] = [:]
        var settled: [String] = []
        for candidate in candidates where candidate.windowsReadable && candidate.windowCount == 0 {
            let start = windowlessSince[candidate.pid] ?? now
            since[candidate.pid] = start
            if now - start >= Self.settleDelay {
                settled.append(candidate.id)
            }
        }
        windowlessSince = since
        return settled
    }

    public static func trayIDs(windowless: [String], pinned: TaskbarPins, excluded: Set<String>) -> [String] {
        var seen = Set<String>()
        return windowless.filter { !pinned.contains($0) && !excluded.contains($0) && seen.insert($0).inserted }
    }

    public static func split<Item>(_ items: [Item]) -> (inline: [Item], opensFlyout: Bool) {
        (Array(items.prefix(inlineLimit)), items.count > inlineLimit)
    }
}
