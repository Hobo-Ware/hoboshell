public enum ShowDesktopAction: Equatable {
    case hide([Int32])
    case restore([Int32])
    case nothing
}

public struct ShowDesktopState: Equatable {
    public private(set) var hidden: [Int32]?

    public init() {
        hidden = nil
    }

    public mutating func toggle(visible: [Int32]) -> ShowDesktopAction {
        if let hidden {
            self.hidden = nil
            return .restore(hidden)
        }
        guard !visible.isEmpty else { return .nothing }
        hidden = visible
        return .hide(visible)
    }

    public mutating func userActivatedApp() {
        hidden = nil
    }
}
