import AppKit
import HoboshellCore

enum StartMenuPages {
    static let pinnedColumns = 5

    private static var icons: [String: NSImage] = [:]

    static func pinned(apps: [StartMenuApp], recents: [URL], actions: StartMenuActions) -> StartMenuPage {
        let allApps = DSButton(
            views: [DSLabel("All apps", style: .caption), DSIconView(side: DSIconSize.chevron, image: DSIconSize.symbol("chevron.right"))],
            height: .compact
        )
        allApps.setAccessibilityLabel("All apps")
        allApps.onPress = actions.showAllApps
        let header = DSHeaderRow(title: "Pinned", trailing: allApps)

        let tiles = apps.map { (id: $0.bundleID ?? $0.url.path, app: $0, cell: tile(for: $0, actions: actions)) }
        var views: [NSView] = [header]
        if tiles.isEmpty {
            views.append(emptyNote("No pinned apps. Right-click an app and pick Pin to Start."))
        } else {
            views.append(StartMenuPinGrid(
                tiles: tiles.map { (id: $0.id, cell: $0.cell) }, columns: pinnedColumns, onMove: actions.movePin
            ))
        }
        var groups = [
            StartMenuGroup(items: [StartMenuItem(view: allApps, activate: actions.showAllApps)], columns: 1),
            StartMenuGroup(items: tiles.map { entry in
                StartMenuItem(view: entry.cell, activate: { actions.open(entry.app) })
            }, columns: pinnedColumns),
        ]
        if !recents.isEmpty {
            views.append(DSSectionHeader("Recent"))
            let rows = recents.map { fileItem($0, actions: actions) }
            views.append(contentsOf: rows.map(\.view))
            groups.append(StartMenuGroup(items: rows, columns: 1))
        }
        return StartMenuPage(view: stack(views, spaceAfterFirst: DSSpacing.xs), groups: groups, entrySection: 1)
    }

    static func allApps(apps: [StartMenuApp], actions: StartMenuActions) -> StartMenuPage {
        let back = DSButton(title: "Back", image: DSIconSize.symbol("chevron.left"), height: .compact)
        back.iconSide = DSIconSize.chevron
        back.setAccessibilityLabel("Back to pinned apps")
        back.onPress = actions.showPinned
        var views: [NSView] = [DSHeaderRow(title: "All apps", leading: back)]
        var rows: [StartMenuItem] = []
        for group in StartLetterGroups.group(apps.map(\.name)) {
            views.append(DSLetterHeader(group.letter))
            for index in group.indices {
                let item = appItem(apps[index], actions: actions)
                views.append(item.view)
                rows.append(item)
            }
        }
        let groups = [StartMenuGroup(items: [StartMenuItem(view: back, activate: actions.showPinned)], columns: 1), StartMenuGroup(items: rows, columns: 1)]
        return StartMenuPage(view: stack(views, spaceAfterFirst: DSSpacing.xs), groups: groups, entrySection: 1)
    }

    static func search(
        query: String, apps: [StartMenuApp], files: [URL], settings: [StartSettingsPane], actions: StartMenuActions
    ) -> StartMenuPage {
        let groups = StartResults.groups(apps: apps.count, files: files.count, settings: settings.count)
        guard !groups.isEmpty else {
            return StartMenuPage(view: stack([emptyNote("No results for \"\(query)\"")], spaceAfterFirst: 0), groups: [], entrySection: 0)
        }
        var views: [NSView] = []
        var menuGroups: [StartMenuGroup] = []
        for group in groups {
            let items: [StartMenuItem]
            switch group.kind {
            case .apps: items = apps.prefix(group.count).map { appItem($0, actions: actions) }
            case .files: items = files.prefix(group.count).map { fileItem($0, actions: actions) }
            case .settings: items = settings.prefix(group.count).map { settingItem($0, actions: actions) }
            }
            views.append(DSSectionHeader(group.kind.title))
            views.append(contentsOf: items.map(\.view))
            menuGroups.append(StartMenuGroup(items: items, columns: 1))
        }
        return StartMenuPage(view: stack(views, spaceAfterFirst: 0), groups: menuGroups, entrySection: 0)
    }

    private static func tile(for app: StartMenuApp, actions: StartMenuActions) -> DSGridCell {
        let cell = DSGridCell()
        cell.show(name: app.name, icon: icon(forFile: app.url.path, side: DSIconSize.grid))
        cell.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cell.widthAnchor.constraint(equalToConstant: DSGridCell.size.width),
            cell.heightAnchor.constraint(equalToConstant: DSGridCell.size.height),
        ])
        cell.menu = actions.appMenu(app)
        cell.onPress = { actions.open(app) }
        return cell
    }

    private static func appItem(_ app: StartMenuApp, actions: StartMenuActions) -> StartMenuItem {
        let row = DSListRow(title: app.name, image: icon(forFile: app.url.path, side: DSIconSize.toolbar))
        row.menu = actions.appMenu(app)
        row.onPress = { actions.open(app) }
        return StartMenuItem(view: row, activate: { actions.open(app) })
    }

    private static func fileItem(_ url: URL, actions: StartMenuActions) -> StartMenuItem {
        let row = DSListRow(
            title: url.lastPathComponent,
            image: icon(forFile: url.path, side: DSIconSize.toolbar),
            detail: url.deletingLastPathComponent().lastPathComponent
        )
        row.menu = actions.fileMenu(url)
        row.onPress = { actions.openFile(url) }
        return StartMenuItem(view: row, activate: { actions.openFile(url) })
    }

    private static func settingItem(_ pane: StartSettingsPane, actions: StartMenuActions) -> StartMenuItem {
        let row = DSListRow(title: pane.name, image: HoboIcon.settings.image(side: DSIconSize.toolbar), detail: "Settings")
        row.onPress = { actions.openSetting(pane) }
        return StartMenuItem(view: row, activate: { actions.openSetting(pane) })
    }

    private static func icon(forFile path: String, side: CGFloat) -> NSImage {
        let key = "\(path)@\(side)"
        if let cached = icons[key] {
            return cached
        }
        let image = HoboIcon.image(forFile: path, side: side)
        icons[key] = image
        return image
    }

    private static func emptyNote(_ text: String) -> NSView {
        let label = DSLabel(text, color: DSColor.dimText)
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        let holder = NSView()
        holder.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: DSSpacing.s),
            label.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -DSSpacing.s),
            label.topAnchor.constraint(equalTo: holder.topAnchor, constant: DSSpacing.s),
            label.bottomAnchor.constraint(equalTo: holder.bottomAnchor, constant: -DSSpacing.s),
        ])
        return holder
    }

    private static func stack(_ views: [NSView], spaceAfterFirst: CGFloat) -> NSStackView {
        let column = NSStackView(views: views)
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = DSSpacing.xxs
        column.translatesAutoresizingMaskIntoConstraints = false
        if let first = views.first {
            column.setCustomSpacing(spaceAfterFirst, after: first)
        }
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            if !(view is StartMenuPinGrid) {
                view.widthAnchor.constraint(equalTo: column.widthAnchor).isActive = true
            }
        }
        return column
    }
}
