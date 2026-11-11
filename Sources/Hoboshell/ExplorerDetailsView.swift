import AppKit
import HoboshellCore

final class ExplorerDetailsView: NSScrollView, ExplorerItemsView, NSTableViewDataSource, NSTableViewDelegate {
    private static let rowHeight = DSControlHeight.row.value
    private static let nameInset = DSSpacing.s + DSIconSize.toolbar + DSSpacing.s

    private struct ColumnSpec {
        let column: ExplorerSortColumn
        let width: CGFloat
        let minWidth: CGFloat
    }

    private static let columns = [
        ColumnSpec(column: .name, width: 320, minWidth: 140),
        ColumnSpec(column: .modified, width: 180, minWidth: 130),
        ColumnSpec(column: .kind, width: 140, minWidth: 80),
        ColumnSpec(column: .size, width: 90, minWidth: 70),
    ]

    weak var itemsDelegate: ExplorerItemsDelegate?

    private let table = ExplorerTable()
    private var entries: [FileEntry] = []
    private var currentSort = ExplorerSort.standard
    private var isApplyingSort = false

    var selectedIndexes: IndexSet {
        get { table.selectedRowIndexes }
        set { table.selectRowIndexes(newValue, byExtendingSelection: false) }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureTable()
        documentView = table
        hasVerticalScroller = true
        drawsBackground = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ entries: [FileEntry], sort: ExplorerSort, selecting paths: Set<String>) {
        self.entries = entries
        currentSort = sort
        isApplyingSort = true
        table.sortDescriptors = [NSSortDescriptor(key: sort.column.rawValue, ascending: sort.ascending)]
        isApplyingSort = false
        table.headerView?.needsDisplay = true
        table.reloadData()
        let rows = IndexSet(entries.indices.filter { paths.contains(entries[$0].url.path) })
        table.selectRowIndexes(rows, byExtendingSelection: false)
    }

    func selectAll() {
        table.selectAll(nil)
    }

    func reveal(_ index: Int) {
        table.scrollRowToVisible(index)
    }

    func focus() {
        window?.makeFirstResponder(table)
    }

    func beginRename(at index: Int) {
        guard entries.indices.contains(index) else { return }
        table.scrollRowToVisible(index)
        guard let cell = table.view(atColumn: 0, row: index, makeIfNecessary: true) as? ExplorerNameCell else { return }
        let entry = entries[index]
        cell.nameField.onCommit = { [weak self] name in
            self?.itemsDelegate?.itemsRename(at: index, to: name)
            self?.focus()
        }
        cell.nameField.onCancel = { [weak self] in
            self?.itemsDelegate?.itemsRenameCancelled()
            self?.focus()
        }
        let began = cell.nameField.beginRenaming(stemLength: ExplorerNaming.stemLength(of: entry.name, isFolder: entry.isFolder))
        if began {
            itemsDelegate?.itemsRenameBegan()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        entries.count
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let row = tableView.makeView(withIdentifier: DSTableRowView.identifier, owner: nil) as? DSTableRowView ?? DSTableRowView()
        row.useAccentStyle()
        return row
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard entries.indices.contains(row), let id = tableColumn?.identifier.rawValue,
              let column = ExplorerSortColumn(rawValue: id) else { return nil }
        let entry = entries[row]
        if column == .name {
            let cell = tableView.makeView(withIdentifier: ExplorerNameCell.identifier, owner: nil) as? ExplorerNameCell ?? ExplorerNameCell()
            cell.show(name: entry.name, icon: HoboIcon.image(forFile: entry.url.path))
            return cell
        }
        let cell = tableView.makeView(withIdentifier: ExplorerTextCell.identifier, owner: nil) as? ExplorerTextCell ?? ExplorerTextCell()
        switch column {
        case .modified: cell.show(ExplorerFormat.dateText(entry.modified), alignment: .left)
        case .kind: cell.show(entry.kind, alignment: .left)
        default: cell.show(ExplorerFormat.sizeText(entry.size), alignment: .right)
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        itemsDelegate?.itemsSelectionChanged()
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard !isApplyingSort, let descriptor = tableView.sortDescriptors.first,
              let key = descriptor.key, let column = ExplorerSortColumn(rawValue: key) else { return }
        let sort = ExplorerSort(column: column, ascending: descriptor.ascending)
        guard sort != currentSort else { return }
        currentSort = sort
        itemsDelegate?.itemsSortChanged(sort)
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        entries.indices.contains(row) ? entries[row].url as NSURL : nil
    }

    func tableView(
        _ tableView: NSTableView,
        validateDrop info: NSDraggingInfo,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        let urls = ExplorerClipboard.fileURLs(from: info.draggingPasteboard)
        guard !urls.isEmpty else { return [] }
        let target = dropTarget(row: row, operation: dropOperation)
        if target == nil {
            tableView.setDropRow(-1, dropOperation: .on)
        }
        return itemsDelegate?.itemsDropOperation(
            urls,
            onto: target,
            option: NSEvent.modifierFlags.contains(.option),
            allowed: info.draggingSourceOperationMask
        ) ?? []
    }

    func tableView(
        _ tableView: NSTableView,
        acceptDrop info: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        let urls = ExplorerClipboard.fileURLs(from: info.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        return itemsDelegate?.itemsAcceptDrop(
            urls,
            onto: dropTarget(row: row, operation: dropOperation),
            option: NSEvent.modifierFlags.contains(.option),
            allowed: info.draggingSourceOperationMask
        ) ?? false
    }

    @objc private func rowDoubleClicked() {
        guard table.clickedRow >= 0 else { return }
        itemsDelegate?.itemsOpen(at: table.clickedRow)
    }

    private func dropTarget(row: Int, operation: NSTableView.DropOperation) -> Int? {
        guard operation == .on, entries.indices.contains(row), entries[row].isFolder else { return nil }
        return row
    }

    private func configureTable() {
        for spec in Self.columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(spec.column.rawValue))
            let isSize = spec.column == .size
            column.headerCell = ExplorerHeaderCell(
                title: spec.column.title,
                sortKey: spec.column.rawValue,
                leadingInset: spec.column == .name ? Self.nameInset : DSSpacing.s,
                trailingInset: isSize ? DSSpacing.m : DSSpacing.s,
                alignment: isSize ? .right : .left
            )
            column.width = spec.width
            column.minWidth = spec.minWidth
            column.sortDescriptorPrototype = NSSortDescriptor(key: spec.column.rawValue, ascending: true)
            table.addTableColumn(column)
        }
        table.headerView = ExplorerHeaderView(frame: NSRect(x: 0, y: 0, width: 0, height: Self.rowHeight))
        table.rowHeight = Self.rowHeight
        table.style = .plain
        table.intercellSpacing = .zero
        table.backgroundColor = .clear
        table.allowsMultipleSelection = true
        table.allowsColumnReordering = false
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.doubleAction = #selector(rowDoubleClicked)
        table.registerForDraggedTypes([.fileURL])
        table.setDraggingSourceOperationMask([.copy, .move, .generic], forLocal: true)
        table.setDraggingSourceOperationMask([.copy, .move, .generic], forLocal: false)
        table.keyHandler = { [weak self] event in
            self?.itemsDelegate?.itemsHandle(event) ?? false
        }
        table.menuProvider = { [weak self] overItem in
            self?.itemsDelegate?.itemsMenu(overItem: overItem) ?? NSMenu()
        }
        table.onSlowClick = { [weak self] row in
            guard let self, self.table.selectedRowIndexes == IndexSet(integer: row) else { return }
            self.beginRename(at: row)
        }
    }
}
