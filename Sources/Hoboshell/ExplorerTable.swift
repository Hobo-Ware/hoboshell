import AppKit

final class ExplorerTable: NSTableView {
    private static let clickSlop: CGFloat = 4

    var keyHandler: ((NSEvent) -> Bool)?
    var menuProvider: ((Bool) -> NSMenu)?
    var onSlowClick: ((Int) -> Void)?

    private let slowClick = ExplorerSlowClick()

    override func keyDown(with event: NSEvent) {
        if keyHandler?(event) == true { return }
        super.keyDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        if row >= 0 {
            if !selectedRowIndexes.contains(row) {
                selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
        } else {
            deselectAll(nil)
        }
        return menuProvider?(row >= 0)
    }

    override func mouseDown(with event: NSEvent) {
        slowClick.cancel()
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        let isPlainClick = event.clickCount == 1 && event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty
        let wasOnlySelection = isPlainClick
            && row >= 0
            && column(at: point) == 0
            && selectedRowIndexes == IndexSet(integer: row)
            && window?.firstResponder === self
        let start = event.locationInWindow
        super.mouseDown(with: event)
        guard wasOnlySelection, let end = window?.mouseLocationOutsideOfEventStream else { return }
        guard abs(end.x - start.x) < Self.clickSlop, abs(end.y - start.y) < Self.clickSlop else { return }
        slowClick.arm { [weak self] in
            self?.onSlowClick?(row)
        }
    }
}
