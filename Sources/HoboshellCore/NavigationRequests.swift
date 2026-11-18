public struct NavigationRequests {
    private var latest: NavigationHistory?

    public init() {}

    public func base(applied: NavigationHistory) -> NavigationHistory {
        latest ?? applied
    }

    public mutating func request(_ history: NavigationHistory) {
        latest = history
    }

    public mutating func settle() {
        latest = nil
    }
}
