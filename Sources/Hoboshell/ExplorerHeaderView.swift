import AppKit

final class ExplorerHeaderView: NSTableHeaderView {
    private static let hairline: CGFloat = 1

    override func draw(_ dirtyRect: NSRect) {
        DSColor.surface.setFill()
        dirtyRect.fill()
        if let table = tableView {
            for (index, column) in table.tableColumns.enumerated() {
                let frame = headerRect(ofColumn: index)
                if frame.intersects(dirtyRect) {
                    column.headerCell.draw(withFrame: frame, in: self)
                }
            }
        }
        DSColor.border.setFill()
        NSRect(x: bounds.minX, y: isFlipped ? bounds.maxY - Self.hairline : bounds.minY, width: bounds.width, height: Self.hairline).fill()
    }
}
