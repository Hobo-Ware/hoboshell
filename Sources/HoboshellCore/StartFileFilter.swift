public enum StartFileFilter {
    public static func isListable(path: String, home: String) -> Bool {
        guard path.hasPrefix(home + "/") else { return false }
        let relative = path.dropFirst(home.count + 1)
        let parts = relative.split(separator: "/").map(String.init)
        guard let last = parts.last else { return false }
        if parts.contains(where: { $0.hasPrefix(".") }) || parts.first == "Library" {
            return false
        }
        return !last.hasSuffix(".app")
    }
}
