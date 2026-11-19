import Foundation

public enum TrashContents: Equatable {
    case unreadable
    case empty
    case items(Int)

    public init(entryNames: [String]?) {
        guard let entryNames else {
            self = .unreadable
            return
        }
        let count = entryNames.filter { !$0.hasPrefix(".") }.count
        self = count == 0 ? .empty : .items(count)
    }

    public var canBrowse: Bool {
        self != .unreadable
    }

    public var isFull: Bool {
        if case .items = self { return true }
        return false
    }

    public var countText: String? {
        guard case .items(let count) = self else { return nil }
        return count == 1 ? "1 item" : "\(count) items"
    }
}
