public struct WindowRecency: Equatable {
    private var order: [Int] = []

    public init() {}

    public var mostRecent: Int? { order.first }

    public mutating func activated(_ id: Int) {
        order.removeAll { $0 == id }
        order.insert(id, at: 0)
    }

    public mutating func forget(_ id: Int) {
        order.removeAll { $0 == id }
    }

    public mutating func forget(keeping live: Set<Int>) {
        order.removeAll { !live.contains($0) }
    }

    public func ordered(_ ids: [Int]) -> [Int] {
        let live = Set(ids)
        let known = order.filter(live.contains)
        let knownSet = Set(known)
        return known + ids.filter { !knownSet.contains($0) }
    }

    public static func keepingOrder(of current: [Int], among live: [Int]) -> [Int] {
        let liveSet = Set(live)
        let kept = current.filter(liveSet.contains)
        let keptSet = Set(kept)
        return kept + live.filter { !keptSet.contains($0) }
    }
}
