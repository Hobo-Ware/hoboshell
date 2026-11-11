public enum ShellVariant: String, CaseIterable {
    case bottomTaskbar = "bottom-taskbar"
    case topBarWithDock = "top-bar-dock"

    public var other: ShellVariant {
        self == .bottomTaskbar ? .topBarWithDock : .bottomTaskbar
    }

    public var displayName: String {
        switch self {
        case .bottomTaskbar: return "bottom taskbar"
        case .topBarWithDock: return "top bar and side dock"
        }
    }

    public static func resolve(arguments: [String], saved: String?) -> ShellVariant {
        if let flag = arguments.firstIndex(of: "--variant"),
           arguments.indices.contains(flag + 1),
           let requested = ShellVariant(rawValue: arguments[flag + 1]) {
            return requested
        }
        return saved.flatMap(ShellVariant.init(rawValue:)) ?? .bottomTaskbar
    }
}
