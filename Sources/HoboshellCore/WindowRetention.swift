import Foundation

public struct WindowRetention {
    public struct Known: Equatable {
        public let id: Int
        public let pid: Int32

        public init(id: Int, pid: Int32) {
            self.id = id
            self.pid = pid
        }
    }

    public static let missesToDrop = 2
    public static let minimumMissGap: TimeInterval = 0.5

    private struct Misses {
        var count: Int
        var lastCountedAt: TimeInterval
    }

    private var misses: [Int: Misses] = [:]

    public init() {}

    public mutating func keptIDs(
        missing: [Known],
        readablePIDs: Set<Int32>,
        runningPIDs: Set<Int32>,
        destroyed: Set<Int>,
        now: TimeInterval
    ) -> Set<Int> {
        var kept = Set<Int>()
        var stillMissing = Set<Int>()
        for window in missing {
            stillMissing.insert(window.id)
            guard runningPIDs.contains(window.pid), !destroyed.contains(window.id) else { continue }
            guard readablePIDs.contains(window.pid) else {
                kept.insert(window.id)
                continue
            }
            if keepsAfterMiss(window.id, now: now) {
                kept.insert(window.id)
            }
        }
        misses = misses.filter { kept.contains($0.key) && stillMissing.contains($0.key) }
        return kept
    }

    private mutating func keepsAfterMiss(_ id: Int, now: TimeInterval) -> Bool {
        var current = misses[id] ?? Misses(count: 0, lastCountedAt: -.infinity)
        if now - current.lastCountedAt >= Self.minimumMissGap {
            current.count += 1
            current.lastCountedAt = now
            misses[id] = current
        }
        return current.count < Self.missesToDrop
    }
}
