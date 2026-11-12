public struct ListDiff<Key: Hashable>: Equatable {
    public let removed: [Key]
    public let inserted: [Key]
    public let isReordered: Bool

    public init(old: [Key], new: [Key]) {
        let oldSet = Set(old)
        let newSet = Set(new)
        removed = old.filter { !newSet.contains($0) }
        inserted = new.filter { !oldSet.contains($0) }
        isReordered = old.filter(newSet.contains) != new.filter(oldSet.contains)
    }

    public var isEmpty: Bool {
        removed.isEmpty && inserted.isEmpty && !isReordered
    }
}
