import AppKit

final class StartMenuPanel: NSPanel, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private static let menuSize = NSSize(width: 360, height: 480)
    private static let rowHeight: CGFloat = 30

    private let search = NSSearchField()
    private let table = NSTableView()
    private let installedApps: [URL]
    private var matches: [URL]

    init() {
        installedApps = Self.findInstalledApps()
        matches = installedApps
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.menuSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        appearance = NSAppearance(named: .darkAqua)
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        buildContent()
    }

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }

    func toggle(origin: (NSSize) -> NSPoint) {
        if isVisible {
            orderOut(nil)
            return
        }
        search.stringValue = ""
        filter()
        setFrameOrigin(origin(frame.size))
        makeKeyAndOrderFront(nil)
        makeFirstResponder(search)
    }

    private static func findInstalledApps() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            home.appendingPathComponent("Applications"),
        ]
        return folders
            .flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
            .filter { $0.pathExtension == "app" }
            .sorted { displayName(of: $0).localizedCaseInsensitiveCompare(displayName(of: $1)) == .orderedAscending }
    }

    private static func displayName(of app: URL) -> String {
        app.deletingPathExtension().lastPathComponent
    }

    private func buildContent() {
        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: Self.menuSize))
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 10
        background.layer?.masksToBounds = true
        contentView = background

        search.placeholderString = "Search apps"
        search.delegate = self
        search.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = Self.rowHeight
        table.backgroundColor = .clear
        table.style = .plain
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(launchClickedRow)

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(search)
        background.addSubview(scroll)
        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: background.topAnchor, constant: 12),
            search.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 12),
            search.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),
            scroll.topAnchor.constraint(equalTo: search.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -4),
            scroll.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -8),
        ])
    }

    private func filter() {
        let query = search.stringValue.trimmingCharacters(in: .whitespaces)
        matches = query.isEmpty
            ? installedApps
            : installedApps.filter { Self.displayName(of: $0).localizedCaseInsensitiveContains(query) }
        table.reloadData()
    }

    private func launch(row: Int) {
        guard matches.indices.contains(row) else { return }
        NSWorkspace.shared.openApplication(at: matches[row], configuration: NSWorkspace.OpenConfiguration())
        orderOut(nil)
    }

    @objc private func launchClickedRow() {
        launch(row: table.clickedRow)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        matches.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = matches[row]
        let icon = NSImageView(image: NSWorkspace.shared.icon(forFile: app.path))
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
        ])
        let name = NSTextField(labelWithString: Self.displayName(of: app))
        name.textColor = .white
        name.lineBreakMode = .byTruncatingTail
        let rowView = NSStackView(views: [icon, name])
        rowView.orientation = .horizontal
        rowView.spacing = 8
        rowView.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return rowView
    }

    func controlTextDidChange(_ notification: Notification) {
        filter()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            launch(row: max(table.selectedRow, 0))
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            orderOut(nil)
            return true
        }
        return false
    }
}
