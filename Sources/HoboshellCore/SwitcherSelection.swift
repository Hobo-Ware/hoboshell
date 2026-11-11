public enum SwitcherSelection {
    public static func initial(count: Int) -> Int? {
        count == 0 ? nil : min(1, count - 1)
    }

    public static func next(after index: Int, count: Int) -> Int? {
        count == 0 ? nil : (index + 1) % count
    }
}
