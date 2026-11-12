import Foundation

public enum ExplorerFilter {
    public static func apply(to entries: [FileEntry], query: String) -> [FileEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter { $0.name.localizedStandardContains(trimmed) }
    }
}
