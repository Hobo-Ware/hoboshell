public enum TaskbarAppID {
    private static let processPrefix = "pid:"

    public static func make(bundleIdentifier: String?, pid: Int32) -> String {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return "\(processPrefix)\(pid)" }
        return bundleIdentifier
    }

    public static func isPinnable(_ id: String) -> Bool {
        !id.hasPrefix(processPrefix)
    }
}
