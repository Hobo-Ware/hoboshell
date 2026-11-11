import AppKit
import HoboshellCore

protocol ExplorerItemsDelegate: AnyObject {
    func itemsSelectionChanged()
    func itemsOpen(at index: Int)
    func itemsRenameBegan()
    func itemsRename(at index: Int, to name: String)
    func itemsRenameCancelled()
    func itemsHandle(_ event: NSEvent) -> Bool
    func itemsMenu(overItem: Bool) -> NSMenu
    func itemsDropOperation(_ urls: [URL], onto index: Int?, option: Bool, allowed: NSDragOperation) -> NSDragOperation
    func itemsAcceptDrop(_ urls: [URL], onto index: Int?, option: Bool, allowed: NSDragOperation) -> Bool
    func itemsSortChanged(_ sort: ExplorerSort)
}

protocol ExplorerItemsView: NSView {
    var itemsDelegate: ExplorerItemsDelegate? { get set }
    var selectedIndexes: IndexSet { get set }
    func show(_ entries: [FileEntry], sort: ExplorerSort, selecting paths: Set<String>)
    func selectAll()
    func reveal(_ index: Int)
    func beginRename(at index: Int)
    func focus()
}
