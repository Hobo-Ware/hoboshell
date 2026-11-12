import Foundation

public enum ExplorerFileError: Error, Equatable, LocalizedError {
    case emptyName
    case invalidName(String)
    case nameTooLong
    case nameTaken(String)
    case intoItself(String)

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "A name cannot be empty."
        case .invalidName(let name):
            return "\"\(name)\" is not a valid name. Names cannot contain / or : ."
        case .nameTooLong:
            return "That name is too long."
        case .nameTaken(let name):
            return "An item named \"\(name)\" already exists here."
        case .intoItself(let name):
            return "\"\(name)\" cannot be moved or copied into itself."
        }
    }
}
