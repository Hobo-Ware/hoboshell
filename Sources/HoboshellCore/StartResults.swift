import Foundation

public enum StartResultKind: CaseIterable, Hashable {
    case apps
    case files
    case settings

    public var title: String {
        switch self {
        case .apps: return "Apps"
        case .files: return "Files"
        case .settings: return "Settings"
        }
    }

    public var limit: Int {
        switch self {
        case .apps: return 8
        case .files: return 8
        case .settings: return 5
        }
    }
}

public struct StartResultGroup: Equatable {
    public let kind: StartResultKind
    public let count: Int

    public init(kind: StartResultKind, count: Int) {
        self.kind = kind
        self.count = count
    }
}

public enum StartResults {
    public static let minimumFileQueryLength = 2

    public static func allowsFileSearch(for query: String) -> Bool {
        query.trimmingCharacters(in: .whitespaces).count >= minimumFileQueryLength
    }

    public static func groups(apps: Int, files: Int, settings: Int) -> [StartResultGroup] {
        let counts: [StartResultKind: Int] = [.apps: apps, .files: files, .settings: settings]
        return StartResultKind.allCases.compactMap { kind in
            let count = min(counts[kind] ?? 0, kind.limit)
            return count > 0 ? StartResultGroup(kind: kind, count: count) : nil
        }
    }

    public static func sections(of groups: [StartResultGroup]) -> [StartSection] {
        groups.map { StartSection(count: $0.count, columns: 1) }
    }
}
