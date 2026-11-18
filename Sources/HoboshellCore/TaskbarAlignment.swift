public enum TaskbarAlignment: String, CaseIterable {
    case left
    case centred

    public init(stored: String?) {
        self = stored.flatMap(Self.init(rawValue:)) ?? .centred
    }

    public var displayName: String {
        switch self {
        case .left: return "Left"
        case .centred: return "Centred"
        }
    }
}

