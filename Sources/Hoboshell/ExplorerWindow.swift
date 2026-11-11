import AppKit
import HoboshellCore

final class ExplorerWindow: NSWindow, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSCollectionViewDataSource {
    private struct Place {
        let name: String
        let url: URL
    }

    private static var openWindows: [ExplorerWindow] = []

    private var folder: URL
    private var entries: [FileEntry] = []
    private var backStack: [URL] = []
    private var forwardStack: [URL] = []
    private let places: [Place]

    private let backButton = NSButton()
    private let forwardButton = NSButton()
    private let upButton = NSButton()
    private let viewModeButton = NSButton()
    private let pathField = NSTextField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let sidebarTable = NSTableView()
    private let fileTable = NSTableView()
    private let fileGrid = NSCollectionView()
    private let listScroll = NSScrollView()
    private let gridScroll = NSScrollView()
    private let dateFormatter = DateFormatter()

    static func open(at folder: URL) {
        let window = ExplorerWindow(folder: folder)
        openWindows.append(window)
        if let last = openWindows.dropLast().last {
            window.setFrameOrigin(NSPoint(x: last.frame.minX + 28, y: last.frame.minY - 28))
        } else {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private init(folder: URL) {
        self.folder = folder
        places = Self.findPlaces()
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        minSize = NSSize(width: 560, height: 320)
        delegate = self
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        buildContent()
        show(folder, recordingHistory: false)
    }

    func windowWillClose(_ notification: Notification) {
        Self.openWindows.removeAll { $0 === self }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        reload()
    }

    private static func findPlaces() -> [Place] {
        let files = FileManager.default
        let home = files.homeDirectoryForCurrentUser
        var places = [
            Place(name: "Home", url: home),
            Place(name: "Desktop", url: home.appendingPathComponent("Desktop")),
            Place(name: "Documents", url: home.appendingPathComponent("Documents")),
            Place(name: "Downloads", url: home.appendingPathComponent("Downloads")),
            Place(name: "Applications", url: URL(fileURLWithPath: "/Applications")),
        ]
        let volumes = files.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey], options: .skipHiddenVolumes) ?? []
        for volume in volumes {
            let name = (try? volume.resourceValues(forKeys: [.volumeNameKey]))?.volumeName ?? volume.lastPathComponent
            places.append(Place(name: name, url: volume))
        }
        return places
    }

    private func buildContent() {
        let root = NSView()
        contentView = root

        configure(backButton, title: "←", action: #selector(goBack))
        configure(forwardButton, title: "→", action: #selector(goForward))
        configure(upButton, title: "↑", action: #selector(goUp))
        configure(viewModeButton, title: "Grid", action: #selector(toggleViewMode))
        let refreshButton = NSButton()
        configure(refreshButton, title: "⟳", action: #selector(reload))
        let newFolderButton = NSButton()
        configure(newFolderButton, title: "New folder", action: #selector(createFolder))

        pathField.target = self
        pathField.action = #selector(goToTypedPath)
        pathField.lineBreakMode = .byTruncatingHead

        let toolbar = NSStackView(views: [backButton, forwardButton, upButton, refreshButton, pathField, newFolderButton, viewModeButton])
        toolbar.orientation = .horizontal
        toolbar.spacing = 6
        toolbar.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        buildSidebar()
        buildFileList()
        buildFileGrid()

        let sidebarScroll = NSScrollView()
        sidebarScroll.documentView = sidebarTable
        sidebarScroll.hasVerticalScroller = true
        sidebarScroll.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let content = NSView()
        for scroll in [listScroll, gridScroll] {
            scroll.hasVerticalScroller = true
            scroll.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(scroll)
            NSLayoutConstraint.activate([
                scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                scroll.topAnchor.constraint(equalTo: content.topAnchor),
                scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            ])
        }
        gridScroll.isHidden = true

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(sidebarScroll)
        split.addArrangedSubview(content)
        split.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(toolbar)
        root.addSubview(split)
        root.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: root.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            split.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            split.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            split.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -4),
            statusLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            statusLabel.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -4),
        ])
    }

    private func configure(_ button: NSButton, title: String, action: Selector) {
        button.title = title
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = action
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func buildSidebar() {
        sidebarTable.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("place")))
        sidebarTable.headerView = nil
        sidebarTable.rowHeight = 26
        sidebarTable.style = .sourceList
        sidebarTable.dataSource = self
        sidebarTable.delegate = self
    }

    private func buildFileList() {
        let columns: [(id: String, title: String, width: CGFloat)] = [
            ("name", "Name", 300),
            ("modified", "Date modified", 150),
            ("size", "Size", 80),
            ("kind", "Type", 150),
        ]
        for column in columns {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.id))
            tableColumn.title = column.title
            tableColumn.width = column.width
            fileTable.addTableColumn(tableColumn)
        }
        fileTable.rowHeight = 24
        fileTable.allowsMultipleSelection = true
        fileTable.usesAlternatingRowBackgroundColors = true
        fileTable.dataSource = self
        fileTable.delegate = self
        fileTable.target = self
        fileTable.doubleAction = #selector(openTargets)
        fileTable.menu = makeFileMenu()
        listScroll.documentView = fileTable
    }

    private func buildFileGrid() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = FileGridItem.size
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        fileGrid.collectionViewLayout = layout
        fileGrid.isSelectable = true
        fileGrid.allowsMultipleSelection = true
        fileGrid.dataSource = self
        fileGrid.register(FileGridItem.self, forItemWithIdentifier: FileGridItem.identifier)
        fileGrid.menu = makeFileMenu()
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(openTargets))
        doubleClick.numberOfClicksRequired = 2
        doubleClick.delaysPrimaryMouseButtonEvents = false
        fileGrid.addGestureRecognizer(doubleClick)
        gridScroll.documentView = fileGrid
    }

    private func makeFileMenu() -> NSMenu {
        let menu = NSMenu()
        let items: [(String, Selector)] = [
            ("Open", #selector(openTargets)),
            ("Rename", #selector(renameTarget)),
            ("Move to Trash", #selector(trashTargets)),
            ("New folder", #selector(createFolder)),
        ]
        for (title, action) in items {
            menu.addItem(withTitle: title, action: action, keyEquivalent: "").target = self
        }
        return menu
    }

    private var targetEntries: [FileEntry] {
        if listScroll.isHidden {
            return fileGrid.selectionIndexPaths.map { entries[$0.item] }
        }
        let clicked = fileTable.clickedRow
        let rows = clicked >= 0 && !fileTable.selectedRowIndexes.contains(clicked)
            ? IndexSet(integer: clicked)
            : fileTable.selectedRowIndexes
        return rows.filter { entries.indices.contains($0) }.map { entries[$0] }
    }

    private func show(_ target: URL, recordingHistory: Bool) {
        let loaded: [FileEntry]
        do {
            loaded = try FileEntry.contents(of: target)
        } catch {
            statusLabel.stringValue = error.localizedDescription
            return
        }
        if recordingHistory, target != folder {
            backStack.append(folder)
            forwardStack.removeAll()
        }
        folder = target
        entries = loaded
        title = target.path == "/" ? "Computer" : target.lastPathComponent
        pathField.stringValue = target.path
        statusLabel.stringValue = entries.count == 1 ? "1 item" : "\(entries.count) items"
        backButton.isEnabled = !backStack.isEmpty
        forwardButton.isEnabled = !forwardStack.isEmpty
        upButton.isEnabled = target.path != "/"
        fileTable.reloadData()
        fileGrid.reloadData()
    }

    private func report(_ error: Error) {
        statusLabel.stringValue = error.localizedDescription
    }

    @objc private func reload() {
        show(folder, recordingHistory: false)
    }

    @objc private func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(folder)
        show(previous, recordingHistory: false)
    }

    @objc private func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(folder)
        show(next, recordingHistory: false)
    }

    @objc private func goUp() {
        show(folder.deletingLastPathComponent(), recordingHistory: true)
    }

    @objc private func goToTypedPath() {
        let typed = NSString(string: pathField.stringValue).expandingTildeInPath
        show(URL(fileURLWithPath: typed), recordingHistory: true)
    }

    @objc private func toggleViewMode() {
        let showsGrid = gridScroll.isHidden
        gridScroll.isHidden = !showsGrid
        listScroll.isHidden = showsGrid
        viewModeButton.title = showsGrid ? "List" : "Grid"
    }

    @objc private func openTargets() {
        for entry in targetEntries {
            if entry.isFolder {
                show(entry.url, recordingHistory: true)
                return
            }
            NSWorkspace.shared.open(entry.url)
        }
    }

    @objc private func renameTarget() {
        guard let entry = targetEntries.first else { return }
        let nameField = NSTextField(string: entry.name)
        nameField.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        let prompt = NSAlert()
        prompt.messageText = "Rename \(entry.name)"
        prompt.accessoryView = nameField
        prompt.addButton(withTitle: "Rename")
        prompt.addButton(withTitle: "Cancel")
        prompt.window.initialFirstResponder = nameField
        prompt.beginSheetModal(for: self) { [weak self] response in
            let newName = nameField.stringValue.trimmingCharacters(in: .whitespaces)
            guard let self, response == .alertFirstButtonReturn, !newName.isEmpty, newName != entry.name else { return }
            do {
                try FileManager.default.moveItem(at: entry.url, to: entry.url.deletingLastPathComponent().appendingPathComponent(newName))
                self.reload()
            } catch {
                self.report(error)
            }
        }
    }

    @objc private func trashTargets() {
        let targets = targetEntries
        do {
            for entry in targets {
                try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
            }
            reload()
        } catch {
            reload()
            report(error)
        }
    }

    @objc private func createFolder() {
        var candidate = folder.appendingPathComponent("New folder")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("New folder (\(suffix))")
            suffix += 1
        }
        do {
            try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: false)
            reload()
        } catch {
            report(error)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === sidebarTable ? places.count : entries.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView === sidebarTable {
            let place = places[row]
            return Self.cell(icon: NSWorkspace.shared.icon(forFile: place.url.path), text: place.name)
        }
        let entry = entries[row]
        switch tableColumn?.identifier.rawValue {
        case "name":
            return Self.cell(icon: NSWorkspace.shared.icon(forFile: entry.url.path), text: entry.name)
        case "modified":
            return Self.cell(icon: nil, text: entry.modified.map { dateFormatter.string(from: $0) } ?? "")
        case "size":
            return Self.cell(icon: nil, text: entry.size.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) } ?? "")
        default:
            return Self.cell(icon: nil, text: entry.kind)
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard notification.object as? NSTableView === sidebarTable, places.indices.contains(sidebarTable.selectedRow) else { return }
        show(places[sidebarTable.selectedRow].url, recordingHistory: true)
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: FileGridItem.identifier, for: indexPath)
        (item as? FileGridItem)?.show(entries[indexPath.item])
        return item
    }

    private static func cell(icon: NSImage?, text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.lineBreakMode = .byTruncatingTail
        let row = NSStackView(views: [label])
        if let icon {
            let iconView = NSImageView(image: icon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 18),
                iconView.heightAnchor.constraint(equalToConstant: 18),
            ])
            row.insertArrangedSubview(iconView, at: 0)
        }
        row.orientation = .horizontal
        row.spacing = 6
        row.edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        return row
    }
}

final class FileGridItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("FileGridItem")
    static let size = NSSize(width: 96, height: 92)

    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "")

    override func loadView() {
        let container = NSView(frame: NSRect(origin: .zero, size: Self.size))
        container.wantsLayer = true
        container.layer?.cornerRadius = 6
        icon.frame = NSRect(x: 24, y: 38, width: 48, height: 48)
        label.frame = NSRect(x: 2, y: 2, width: 92, height: 32)
        label.alignment = .center
        label.font = .systemFont(ofSize: 11)
        label.maximumNumberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        container.addSubview(icon)
        container.addSubview(label)
        view = container
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.35).cgColor
                : nil
        }
    }

    func show(_ entry: FileEntry) {
        icon.image = NSWorkspace.shared.icon(forFile: entry.url.path)
        label.stringValue = entry.name
    }
}
