public enum SwitcherModifier: Equatable {
    case command
    case option
}

public enum SwitcherAction: Equatable {
    case open(forward: Bool)
    case advance(forward: Bool)
    case move(SwitcherDirection)
    case cancel
    case quitSelected
    case closeSelected
    case commit
}

public struct SwitcherKeyEvent: Equatable {
    public enum Kind: Equatable {
        case keyDown
        case keyUp
        case flagsChanged
    }

    public let kind: Kind
    public let keyCode: Int
    public let command: Bool
    public let option: Bool
    public let control: Bool
    public let shift: Bool

    public init(kind: Kind, keyCode: Int, command: Bool = false, option: Bool = false, control: Bool = false, shift: Bool = false) {
        self.kind = kind
        self.keyCode = keyCode
        self.command = command
        self.option = option
        self.control = control
        self.shift = shift
    }
}

public struct SwitcherTapDecision: Equatable {
    public let swallow: Bool
    public let action: SwitcherAction?

    public static let pass = SwitcherTapDecision(swallow: false, action: nil)

    static func swallowing(_ action: SwitcherAction? = nil) -> SwitcherTapDecision {
        SwitcherTapDecision(swallow: true, action: action)
    }
}

public enum SwitcherKeyPolicy {
    private static let tab = 48
    private static let escape = 53
    private static let leftArrow = 123
    private static let rightArrow = 124
    private static let downArrow = 125
    private static let upArrow = 126
    private static let keyQ = 12
    private static let keyW = 13

    public static func decide(_ event: SwitcherKeyEvent, holder: SwitcherModifier?, takesCommandTab: Bool) -> SwitcherTapDecision {
        guard let holder else {
            return opens(event, takesCommandTab: takesCommandTab)
        }
        return handles(event, holder: holder)
    }

    private static func opens(_ event: SwitcherKeyEvent, takesCommandTab: Bool) -> SwitcherTapDecision {
        guard takesCommandTab, event.kind == .keyDown, event.keyCode == tab,
              event.command, !event.option, !event.control else { return .pass }
        return .swallowing(.open(forward: !event.shift))
    }

    private static func handles(_ event: SwitcherKeyEvent, holder: SwitcherModifier) -> SwitcherTapDecision {
        switch event.kind {
        case .flagsChanged:
            let isHeld = holder == .command ? event.command : event.option
            return isHeld ? .pass : SwitcherTapDecision(swallow: false, action: .commit)
        case .keyDown:
            guard let action = action(forKeyCode: event.keyCode, shift: event.shift) else { return .pass }
            return .swallowing(action)
        case .keyUp:
            return action(forKeyCode: event.keyCode, shift: false) == nil ? .pass : .swallowing()
        }
    }

    private static func action(forKeyCode keyCode: Int, shift: Bool) -> SwitcherAction? {
        switch keyCode {
        case tab: return .advance(forward: !shift)
        case leftArrow: return .move(.left)
        case rightArrow: return .move(.right)
        case upArrow: return .move(.up)
        case downArrow: return .move(.down)
        case escape: return .cancel
        case keyQ: return .quitSelected
        case keyW: return .closeSelected
        default: return nil
        }
    }
}
