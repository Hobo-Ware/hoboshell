import Foundation

public enum ExplorerSortColumn: String, CaseIterable {
    case name
    case modified
    case kind
    case size

    public var title: String {
        switch self {
        case .name: return "Name"
        case .modified: return "Date modified"
        case .kind: return "Type"
        case .size: return "Size"
        }
    }
}

public struct ExplorerSort: Equatable {
    public var column: ExplorerSortColumn
    public var ascending: Bool

    public static let standard = ExplorerSort(column: .name, ascending: true)

    public init(column: ExplorerSortColumn, ascending: Bool) {
        self.column = column
        self.ascending = ascending
    }

    public func choosing(_ chosen: ExplorerSortColumn) -> ExplorerSort {
        column == chosen
            ? ExplorerSort(column: column, ascending: !ascending)
            : ExplorerSort(column: chosen, ascending: true)
    }

    public func apply(to entries: [FileEntry]) -> [FileEntry] {
        entries.sorted { first, second in
            if first.isFolder != second.isFolder {
                return first.isFolder
            }
            let order = compare(first, second)
            if order != .orderedSame {
                return ascending ? order == .orderedAscending : order == .orderedDescending
            }
            return first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
    }

    private func compare(_ first: FileEntry, _ second: FileEntry) -> ComparisonResult {
        switch column {
        case .name:
            return first.name.localizedStandardCompare(second.name)
        case .modified:
            return Self.compare(first.modified ?? .distantPast, second.modified ?? .distantPast)
        case .kind:
            return first.kind.localizedStandardCompare(second.kind)
        case .size:
            return Self.compare(first.size ?? -1, second.size ?? -1)
        }
    }

    private static func compare<T: Comparable>(_ first: T, _ second: T) -> ComparisonResult {
        if first == second { return .orderedSame }
        return first < second ? .orderedAscending : .orderedDescending
    }
}
