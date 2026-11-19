public enum StartPinSeed {
    public static let firstSeed = [
        "com.apple.Safari",
        "com.apple.mail",
        "com.apple.iCal",
        "com.apple.Notes",
        "com.apple.Music",
        "com.apple.Photos",
        "com.apple.systempreferences",
        "com.apple.Terminal",
    ]

    public static let bundleIdentifiers = ["com.apple.finder"] + firstSeed

    public static func pins(stored: [String]?, offered: [String]?, isInstalled: (String) -> Bool) -> TaskbarPins {
        guard let stored else {
            return TaskbarPins(bundleIdentifiers.filter(isInstalled))
        }
        let seen = Set(offered ?? firstSeed).union(stored)
        let fresh = bundleIdentifiers.filter { !seen.contains($0) && isInstalled($0) }
        return TaskbarPins(fresh + stored)
    }
}
