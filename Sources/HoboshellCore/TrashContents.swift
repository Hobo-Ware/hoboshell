import Foundation

public enum TrashContents: Equatable {
    case unreadable
    case empty
    case items(Int)
    case privateItems(Int)

    public static let knownHiddenNames = [".DS_Store", ".localized"]

    public init(entryNames: [String]?) {
        guard let entryNames else {
            self = .unreadable
            return
        }
        let count = entryNames.filter { !$0.hasPrefix(".") }.count
        self = count == 0 ? .empty : .items(count)
    }

    // On APFS a folder's link count is 2 plus one per entry, and macOS allows reading it when listing is blocked.
    public init(folderLinkCount: Int, hiddenEntryCount: Int) {
        let count = folderLinkCount - 2 - hiddenEntryCount
        self = count > 0 ? .privateItems(count) : .unreadable
    }

    public var canBrowse: Bool {
        switch self {
        case .empty, .items: return true
        case .unreadable, .privateItems: return false
        }
    }

    public var isFull: Bool {
        itemCount > 0
    }

    public var countText: String? {
        let count = itemCount
        guard count > 0 else { return nil }
        return count == 1 ? "1 item" : "\(count) items"
    }

    private var itemCount: Int {
        switch self {
        case .items(let count), .privateItems(let count): return count
        case .unreadable, .empty: return 0
        }
    }
}
