import Foundation

public enum ExplorerAction: Equatable {
    case back
    case forward
    case up
    case open
    case rename
    case copy
    case cut
    case paste
    case selectAll
    case trash
    case newFolder
    case focusAddress
    case focusSearch
    case quickLook
    case refresh
    case closeWindow
}

public struct ExplorerKeyInput: Equatable {
    public let characters: String
    public let keyCode: UInt16
    public let command: Bool
    public let shift: Bool
    public let option: Bool
    public let control: Bool

    public init(characters: String, keyCode: UInt16, command: Bool = false, shift: Bool = false, option: Bool = false, control: Bool = false) {
        self.characters = characters
        self.keyCode = keyCode
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
    }
}

public enum ExplorerShortcut {
    private static let returnKey: UInt16 = 36
    private static let keypadEnter: UInt16 = 76
    private static let backspace: UInt16 = 51
    private static let forwardDelete: UInt16 = 117
    private static let space: UInt16 = 49
    private static let upArrow: UInt16 = 126
    private static let downArrow: UInt16 = 125
    private static let f2: UInt16 = 120
    private static let f5: UInt16 = 96

    public static func action(for input: ExplorerKeyInput) -> ExplorerAction? {
        guard !input.control else { return nil }
        return input.command ? commandAction(input) : plainAction(input)
    }

    private static func commandAction(_ input: ExplorerKeyInput) -> ExplorerAction? {
        guard !input.option else { return nil }
        switch input.keyCode {
        case upArrow: return input.shift ? nil : .up
        case downArrow: return input.shift ? nil : .open
        case backspace: return input.shift ? nil : .trash
        default: break
        }
        switch input.characters.lowercased() {
        case "[": return .back
        case "]": return .forward
        case "n": return input.shift ? .newFolder : nil
        case _ where input.shift: return nil
        case "c": return .copy
        case "x": return .cut
        case "v": return .paste
        case "a": return .selectAll
        case "l": return .focusAddress
        case "f": return .focusSearch
        case "r": return .refresh
        case "w": return .closeWindow
        default: return nil
        }
    }

    private static func plainAction(_ input: ExplorerKeyInput) -> ExplorerAction? {
        guard !input.option, !input.shift else { return nil }
        switch input.keyCode {
        case returnKey, keypadEnter: return .open
        case backspace: return .up
        case forwardDelete: return .trash
        case f2: return .rename
        case f5: return .refresh
        case space: return .quickLook
        default: return nil
        }
    }
}
