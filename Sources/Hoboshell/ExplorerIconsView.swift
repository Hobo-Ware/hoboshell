import AppKit
import HoboshellCore

final class ExplorerIconsView: NSScrollView, ExplorerItemsView, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private static let spacing = DSSpacing.s
    private static let inset = DSSpacing.m

    weak var itemsDelegate: ExplorerItemsDelegate?

    private let collection = ExplorerCollection()
    private var entries: [FileEntry] = []

    var selectedIndexes: IndexSet {
        get { IndexSet(collection.selectionIndexPaths.map(\.item)) }
        set { collection.selectionIndexPaths = Set(newValue.map { IndexPath(item: $0, section: 0) }) }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureCollection()
        documentView = collection
        hasVerticalScroller = true
        drawsBackground = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ entries: [FileEntry], sort: ExplorerSort, selecting paths: Set<String>) {
        self.entries = entries
        collection.reloadData()
        let paths = entries.indices.filter { paths.contains(entries[$0].url.path) }.map { IndexPath(item: $0, section: 0) }
        collection.selectionIndexPaths = Set(paths)
    }

    func selectAll() {
        collection.selectAll(nil)
    }

    func reveal(_ index: Int) {
        collection.scrollToItems(at: [IndexPath(item: index, section: 0)], scrollPosition: .nearestVerticalEdge)
    }

    func focus() {
        window?.makeFirstResponder(collection)
    }

    func beginRename(at index: Int) {
        guard entries.indices.contains(index) else { return }
        let path = IndexPath(item: index, section: 0)
        collection.scrollToItems(at: [path], scrollPosition: .nearestVerticalEdge)
        guard let item = collection.item(at: path) as? ExplorerIconItem else { return }
        let entry = entries[index]
        item.nameField.onCommit = { [weak self] name in
            self?.itemsDelegate?.itemsRename(at: index, to: name)
            self?.focus()
        }
        item.nameField.onCancel = { [weak self] in
            self?.itemsDelegate?.itemsRenameCancelled()
            self?.focus()
        }
        let began = item.nameField.beginRenaming(stemLength: ExplorerNaming.stemLength(of: entry.name, isFolder: entry.isFolder))
        if began {
            itemsDelegate?.itemsRenameBegan()
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ExplorerIconItem.identifier, for: indexPath)
        if let item = item as? ExplorerIconItem, entries.indices.contains(indexPath.item) {
            let entry = entries[indexPath.item]
            item.show(entry.url, name: entry.name)
        }
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        itemsDelegate?.itemsSelectionChanged()
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        itemsDelegate?.itemsSelectionChanged()
    }

    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        entries.indices.contains(indexPath.item) ? entries[indexPath.item].url as NSURL : nil
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        validateDrop draggingInfo: NSDraggingInfo,
        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        let urls = ExplorerClipboard.fileURLs(from: draggingInfo.draggingPasteboard)
        guard !urls.isEmpty else { return [] }
        let target = dropTarget(path: proposedDropIndexPath.pointee as IndexPath, operation: proposedDropOperation.pointee)
        if target == nil {
            proposedDropIndexPath.pointee = NSIndexPath(forItem: entries.count, inSection: 0)
            proposedDropOperation.pointee = .before
        }
        return itemsDelegate?.itemsDropOperation(
            urls,
            onto: target,
            option: NSEvent.modifierFlags.contains(.option),
            allowed: draggingInfo.draggingSourceOperationMask
        ) ?? []
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        acceptDrop draggingInfo: NSDraggingInfo,
        indexPath: IndexPath,
        dropOperation: NSCollectionView.DropOperation
    ) -> Bool {
        let urls = ExplorerClipboard.fileURLs(from: draggingInfo.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        return itemsDelegate?.itemsAcceptDrop(
            urls,
            onto: dropTarget(path: indexPath, operation: dropOperation),
            option: NSEvent.modifierFlags.contains(.option),
            allowed: draggingInfo.draggingSourceOperationMask
        ) ?? false
    }

    private func dropTarget(path: IndexPath, operation: NSCollectionView.DropOperation) -> Int? {
        guard operation == .on, entries.indices.contains(path.item), entries[path.item].isFolder else { return nil }
        return path.item
    }

    private func configureCollection() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = DSGridCell.size
        layout.minimumInteritemSpacing = Self.spacing
        layout.minimumLineSpacing = Self.spacing
        layout.sectionInset = NSEdgeInsets(top: Self.inset, left: Self.inset, bottom: Self.inset, right: Self.inset)
        collection.collectionViewLayout = layout
        collection.isSelectable = true
        collection.allowsMultipleSelection = true
        collection.backgroundColors = [.clear]
        collection.dataSource = self
        collection.delegate = self
        collection.register(ExplorerIconItem.self, forItemWithIdentifier: ExplorerIconItem.identifier)
        collection.registerForDraggedTypes([.fileURL])
        collection.setDraggingSourceOperationMask([.copy, .move, .generic], forLocal: true)
        collection.setDraggingSourceOperationMask([.copy, .move, .generic], forLocal: false)
        collection.keyHandler = { [weak self] event in
            self?.itemsDelegate?.itemsHandle(event) ?? false
        }
        collection.menuProvider = { [weak self] overItem in
            self?.itemsDelegate?.itemsMenu(overItem: overItem) ?? NSMenu()
        }
        collection.onDoubleClick = { [weak self] index in
            self?.itemsDelegate?.itemsOpen(at: index)
        }
        collection.onSlowClick = { [weak self] index in
            guard let self, self.selectedIndexes == IndexSet(integer: index) else { return }
            self.beginRename(at: index)
        }
    }
}
