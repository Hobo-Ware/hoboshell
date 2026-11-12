public enum StartPinSeed {
    public static let bundleIdentifiers = [
        "com.apple.Safari",
        "com.apple.mail",
        "com.apple.iCal",
        "com.apple.Notes",
        "com.apple.Music",
        "com.apple.Photos",
        "com.apple.systempreferences",
        "com.apple.Terminal",
    ]

    public static func pins(stored: [String]?, isInstalled: (String) -> Bool) -> TaskbarPins {
        if let stored {
            return TaskbarPins(stored)
        }
        return TaskbarPins(bundleIdentifiers.filter(isInstalled))
    }
}
