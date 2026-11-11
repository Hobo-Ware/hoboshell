import AppKit

final class ExplorerCollection: NSCollectionView {
    private static let clickSlop: CGFloat = 4

    var keyHandler: ((NSEvent) -> Bool)?
    var menuProvider: ((Bool) -> NSMenu)?
    var onDoubleClick: ((Int) -> Void)?
    var onSlowClick: ((Int) -> Void)?

    private let slowClick = ExplorerSlowClick()

    override func keyDown(with event: NSEvent) {
        if keyHandler?(event) == true { return }
        super.keyDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        if let path = indexPathForItem(at: point) {
            if !selectionIndexPaths.contains(path) {
                selectionIndexPaths = [path]
            }
            return menuProvider?(true)
        }
        selectionIndexPaths = []
        return menuProvider?(false)
    }

    override func mouseDown(with event: NSEvent) {
        slowClick.cancel()
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        let path = indexPathForItem(at: point)
        let isPlainClick = event.clickCount == 1 && event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty
        let wasOnlySelection = isPlainClick && path != nil && selectionIndexPaths == Set(path.map { [$0] } ?? [])
        let start = event.locationInWindow
        super.mouseDown(with: event)
        guard let path else { return }
        if event.clickCount == 2 {
            onDoubleClick?(path.item)
            return
        }
        guard wasOnlySelection, let end = window?.mouseLocationOutsideOfEventStream else { return }
        guard abs(end.x - start.x) < Self.clickSlop, abs(end.y - start.y) < Self.clickSlop else { return }
        slowClick.arm { [weak self] in
            self?.onSlowClick?(path.item)
        }
    }
}
