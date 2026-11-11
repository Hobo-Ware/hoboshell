public enum TaskbarGrouping: String, CaseIterable {
    case never
    case whenFull
    case always

    public init(stored: String?) {
        self = stored.flatMap(TaskbarGrouping.init(rawValue:)) ?? .whenFull
    }

    public var displayName: String {
        switch self {
        case .never: return "Never"
        case .whenFull: return "When the taskbar is full"
        case .always: return "Always"
        }
    }
}
