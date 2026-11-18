import AppKit
import HoboshellCore

final class ExplorerSidebarView: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
    private enum Row {
        case header(String)
        case place(ExplorerPlace)
        case divider
    }

    private static let rowHeight = DSControlHeight.row.value
    private static let dividerRowHeight = DSSpacing.m

    var onSelect: ((URL) -> Void)?
    var onTrashDrop: (([URL]) -> Void)?

    private let table = NSTableView()
    private var rows: [Row] = []
    private var current: String?
    private var isSyncing = false
    private var observers: [NSObjectProtocol] = []
    private var trashObserver: NSObjectProtocol?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        table.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("place")))
        table.headerView = nil
        table.style = .plain
        table.floatsGroupRows = false
        table.intercellSpacing = .zero
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.registerForDraggedTypes([.fileURL])
        documentView = table
        hasVerticalScroller = true
        drawsBackground = false
        reload()
        observeVolumes()
        trashObserver = NotificationCenter.default.addObserver(
            forName: TrashMonitor.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshTrashRow()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        if let trashObserver {
            NotificationCenter.default.removeObserver(trashObserver)
        }
    }

    func highlight(_ folder: URL) {
        current = folder.standardizedFileURL.path
        syncSelection()
    }

    func reload() {
        let files = FileManager.default
        let quickAccess = ExplorerPlaces.quickAccess(
            home: files.homeDirectoryForCurrentUser,
            applications: URL(fileURLWithPath: "/Applications")
        ) { files.fileExists(atPath: $0.path) }
        rows = [.header("Quick access")] + quickAccess.map(Row.place)
        rows.append(.header("Drives"))
        rows += Self.drives().map(Row.place)
        rows.append(.divider)
        rows.append(.place(ExplorerPlace(name: "Trash", url: TrashMonitor.folder)))
        table.reloadData()
        syncSelection()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if case .header = rows[row] { return true }
        return false
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if case .place = rows[row] { return true }
        return false
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .header: return DSSectionHeader.height
        case .divider: return Self.dividerRowHeight
        case .place: return Self.rowHeight
        }
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let row = tableView.makeView(withIdentifier: DSTableRowView.identifier, owner: nil) as? DSTableRowView ?? DSTableRowView()
        row.useAccentStyle()
        return row
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .header(let title):
            return DSSectionHeader(title)
        case .place(let place):
            return Self.placeCell(place)
        case .divider:
            return Self.dividerCell()
        }
    }

    func tableView(
        _ tableView: NSTableView,
        validateDrop info: NSDraggingInfo,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        guard rows.indices.contains(row), isTrash(rows[row]), !TrashActions.droppedURLs(in: info).isEmpty else { return [] }
        tableView.setDropRow(row, dropOperation: .on)
        return .move
    }

    func tableView(
        _ tableView: NSTableView,
        acceptDrop info: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        let urls = TrashActions.droppedURLs(in: info)
        guard rows.indices.contains(row), isTrash(rows[row]), !urls.isEmpty else { return false }
        onTrashDrop?(urls)
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isSyncing, table.selectedRow >= 0, case .place(let place) = rows[table.selectedRow] else { return }
        onSelect?(place.url)
    }

    private static func drives() -> [ExplorerPlace] {
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey],
            options: .skipHiddenVolumes
        ) ?? []
        return volumes.map { volume in
            let name = (try? volume.resourceValues(forKeys: [.volumeNameKey]))?.volumeName ?? volume.lastPathComponent
            return ExplorerPlace(name: name, url: volume)
        }
    }

    private static func dividerCell() -> NSView {
        let cell = NSView()
        let line = DSDivider()
        cell.addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: DSSpacing.s),
            line.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -DSSpacing.s),
            line.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    private static func isTrash(_ place: ExplorerPlace) -> Bool {
        place.url.standardizedFileURL.path == TrashMonitor.folder.standardizedFileURL.path
    }

    private static func icon(for place: ExplorerPlace) -> NSImage {
        guard isTrash(place) else { return HoboIcon.image(forFile: place.url.path) }
        let icon = TrashMonitor.shared.contents.isFull ? HoboIcon.trashFull : HoboIcon.trashEmpty
        return icon.image(side: DSIconSize.grid) ?? HoboIcon.image(forFile: place.url.path)
    }

    private func isTrash(_ row: Row) -> Bool {
        if case .place(let place) = row { return Self.isTrash(place) }
        return false
    }

    private func refreshTrashRow() {
        guard let index = rows.firstIndex(where: isTrash) else { return }
        table.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }

    private static func placeCell(_ place: ExplorerPlace) -> NSView {
        let cell = DSListRow(
            title: place.name,
            image: icon(for: place),
            height: .row
        )
        cell.makeStatic()
        return cell
    }

    private func syncSelection() {
        isSyncing = true
        defer { isSyncing = false }
        let match = rows.firstIndex { row in
            if case .place(let place) = row { return place.url.standardizedFileURL.path == current }
            return false
        }
        if let match {
            table.selectRowIndexes(IndexSet(integer: match), byExtendingSelection: false)
        } else {
            table.deselectAll(nil)
        }
    }

    private func observeVolumes() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didMountNotification,
            NSWorkspace.didUnmountNotification,
            NSWorkspace.didRenameVolumeNotification,
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.reload()
            }
        }
    }
}
