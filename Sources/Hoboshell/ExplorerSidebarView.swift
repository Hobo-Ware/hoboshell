import AppKit
import HoboshellCore

final class ExplorerSidebarView: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
    private enum Row {
        case header(String)
        case place(ExplorerPlace)
    }

    private static let rowHeight = DSControlHeight.compact.value
    private static let headerHeight = DSControlHeight.compact.value

    var onSelect: ((URL) -> Void)?

    private let table = NSTableView()
    private var rows: [Row] = []
    private var current: String?
    private var isSyncing = false
    private var observers: [NSObjectProtocol] = []

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
        documentView = table
        hasVerticalScroller = true
        drawsBackground = false
        reload()
        observeVolumes()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
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
        if let trash = files.urls(for: .trashDirectory, in: .userDomainMask).first {
            rows.append(.place(ExplorerPlace(name: "Trash", url: trash)))
        }
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
        if case .header = rows[row] { return Self.headerHeight }
        return Self.rowHeight
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView.makeView(withIdentifier: DSTableRowView.identifier, owner: nil) as? DSTableRowView ?? DSTableRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .header(let title):
            return DSSectionHeader(title)
        case .place(let place):
            return Self.placeCell(place)
        }
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

    private static func placeCell(_ place: ExplorerPlace) -> NSView {
        let cell = DSListRow(
            title: place.name,
            image: NSWorkspace.shared.icon(forFile: place.url.path),
            height: .compact
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
