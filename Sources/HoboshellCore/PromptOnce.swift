public struct PromptOnce {
    private var asked = false

    public init() {}

    public mutating func shouldAsk() -> Bool {
        defer { asked = true }
        return !asked
    }
}
