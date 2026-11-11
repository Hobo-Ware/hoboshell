import AppKit

final class StartMenuPanel: NSPanel, NSTableViewDataSource, NSTableViewDelegate {
    private static let menuSize = NSSize(width: 360, height: 480)

    private let search = DSSearchField(placeholder: "Search apps")
    private let table = NSTableView()
    private let installedApps: [URL]
    private var matches: [URL]

    init() {
        installedApps = Self.findInstalledApps()
        matches = installedApps
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.menuSize),
            styleMask: DSPanelStyle.styleMask,
            backing: .buffered,
            defer: false
        )
        buildContent(in: DSPanelStyle.apply(to: self, kind: .flyout))
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
        search.focus()
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

    private func buildContent(in background: DSCard) {
        search.onChange = { [weak self] _ in
            self?.filter()
        }
        search.onSubmit = { [weak self] _ in
            guard let self else { return }
            self.launch(row: max(self.table.selectedRow, 0))
        }
        search.onCancel = { [weak self] in
            self?.orderOut(nil)
        }
        search.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = DSControlHeight.regular.value
        table.intercellSpacing = .zero
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
            search.topAnchor.constraint(equalTo: background.topAnchor, constant: DSSpacing.m),
            search.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            search.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            scroll.topAnchor.constraint(equalTo: search.bottomAnchor, constant: DSSpacing.s),
            scroll.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            scroll.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            scroll.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -DSSpacing.m),
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

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView.makeView(withIdentifier: DSTableRowView.identifier, owner: nil) as? DSTableRowView ?? DSTableRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = matches[row]
        let rowView = DSListRow(title: Self.displayName(of: app), image: NSWorkspace.shared.icon(forFile: app.path))
        rowView.makeStatic()
        return rowView
    }
}
