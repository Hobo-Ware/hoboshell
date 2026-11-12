import Foundation

public enum ExplorerStatusText {
    public static func text(itemCount: Int, selection: [FileEntry]) -> String {
        let items = itemCount == 1 ? "1 item" : "\(itemCount) items"
        guard !selection.isEmpty else { return items }
        let sizes = selection.compactMap(\.size)
        let selected = "\(selection.count) selected"
        guard !sizes.isEmpty else { return "\(items) - \(selected)" }
        return "\(items) - \(selected), \(ExplorerFormat.sizeText(sizes.reduce(0, +)))"
    }
}
