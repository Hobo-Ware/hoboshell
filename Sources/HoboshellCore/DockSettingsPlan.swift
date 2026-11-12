public enum DockSettingKind: Equatable {
    case bool
    case int
    case float
    case string

    public var flag: String {
        switch self {
        case .bool: return "-bool"
        case .int: return "-int"
        case .float: return "-float"
        case .string: return "-string"
        }
    }
}

public struct DockSetting: Equatable {
    public let domain: String
    public let key: String
    public let kind: DockSettingKind

    public var id: String { "\(domain)/\(key)" }
}

public enum DockSettingChange: Equatable {
    case write(DockSetting, String)
    case delete(DockSetting)
}

public enum DockSettingsPlan {
    public static let absent = ""

    public static let autohide = DockSetting(domain: "com.apple.dock", key: "autohide", kind: .bool)
    public static let autohideDelay = DockSetting(domain: "com.apple.dock", key: "autohide-delay", kind: .float)
    public static let tileSize = DockSetting(domain: "com.apple.dock", key: "tilesize", kind: .int)
    public static let orientation = DockSetting(domain: "com.apple.dock", key: "orientation", kind: .string)
    public static let magnification = DockSetting(domain: "com.apple.dock", key: "magnification", kind: .bool)
    public static let showRecents = DockSetting(domain: "com.apple.dock", key: "show-recents", kind: .bool)
    public static let largeSize = DockSetting(domain: "com.apple.dock", key: "largesize", kind: .int)
    public static let createDesktop = DockSetting(domain: "com.apple.finder", key: "CreateDesktop", kind: .bool)

    public static let saved = [
        autohide, autohideDelay, tileSize, orientation, magnification, showRecents, largeSize, createDesktop,
    ]

    public static func changes(for edge: DockEdge, tileSize size: Int) -> [DockSettingChange] {
        [
            .write(autohide, "false"),
            .delete(autohideDelay),
            .write(magnification, "false"),
            .write(showRecents, "false"),
            .write(orientation, edge.rawValue),
            .write(tileSize, "\(size)"),
            .write(createDesktop, "false"),
        ]
    }

    public static func tileSizeChange(_ size: Int) -> DockSettingChange {
        .write(tileSize, "\(size)")
    }

    public static func restoreChanges(saved values: [String: String]) -> [DockSettingChange] {
        saved.compactMap { setting in
            guard let previous = values[setting.id] else { return nil }
            return previous == absent ? .delete(setting) : .write(setting, writable(previous, kind: setting.kind))
        }
    }

    private static func writable(_ value: String, kind: DockSettingKind) -> String {
        guard kind == .bool else { return value }
        switch value {
        case "1": return "true"
        case "0": return "false"
        default: return value
        }
    }
}
