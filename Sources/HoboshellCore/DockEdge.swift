public enum DockEdge: String, CaseIterable {
    case bottom
    case left
}

extension ShellVariant {
    public var dockEdge: DockEdge {
        switch self {
        case .bottomTaskbar: return .bottom
        case .topBarWithDock: return .left
        }
    }
}
