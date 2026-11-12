public enum SwitcherSelection {
    public static func initial(count: Int, forward: Bool = true) -> Int? {
        guard count > 0 else { return nil }
        return forward ? min(1, count - 1) : count - 1
    }

    public static func next(after index: Int, count: Int) -> Int? {
        count == 0 ? nil : (index + 1) % count
    }

    public static func previous(before index: Int, count: Int) -> Int? {
        count == 0 ? nil : (index - 1 + count) % count
    }

    public static func step(from index: Int, forward: Bool, count: Int) -> Int? {
        forward ? next(after: index, count: count) : previous(before: index, count: count)
    }
}
