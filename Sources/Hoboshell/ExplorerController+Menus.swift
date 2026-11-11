import AppKit
import HoboshellCore

extension ExplorerController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(paste):
            return clipboard.hasFiles && canWriteHere
        case #selector(newFolder):
            return canWriteHere
        case #selector(openSelection), #selector(openSelectionWithDefaultApp), #selector(cutSelection),
             #selector(copySelection), #selector(renameSelection), #selector(trashSelection):
            return !selectedEntries.isEmpty
        default:
            return true
        }
    }

    @objc func showSortMenu(_ sender: NSButton) {
        makeSortMenu().popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: sender)
    }

    @objc func chooseSortColumn(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let column = ExplorerSortColumn(rawValue: raw) else { return }
        applySort(ExplorerSort(column: column, ascending: sort.ascending))
    }

    @objc func chooseSortDirection(_ sender: NSMenuItem) {
        applySort(ExplorerSort(column: sort.column, ascending: sender.tag == 0))
    }

    func makeItemMenu() -> NSMenu {
        let menu = NSMenu()
        addItem("Open", #selector(openSelection), to: menu)
        addItem("Open with default app", #selector(openSelectionWithDefaultApp), to: menu)
        menu.addItem(.separator())
        addItem("Cut", #selector(cutSelection), to: menu)
        addItem("Copy", #selector(copySelection), to: menu)
        addItem("Rename", #selector(renameSelection), to: menu)
        addItem("Move to Trash", #selector(trashSelection), to: menu)
        menu.addItem(.separator())
        addItem("Copy path", #selector(copyPath), to: menu)
        addItem("Show in Finder", #selector(showInFinder), to: menu)
        return menu
    }

    func makeEmptyMenu() -> NSMenu {
        let menu = NSMenu()
        addItem("New folder", #selector(newFolder), to: menu)
        addItem("Paste", #selector(paste), to: menu)
        menu.addItem(.separator())
        addSubmenu("Sort by", makeSortMenu(), to: menu)
        addSubmenu("View", makeViewMenu(), to: menu)
        menu.addItem(.separator())
        addItem("Refresh", #selector(refresh), to: menu)
        return menu
    }

    private func makeSortMenu() -> NSMenu {
        let menu = NSMenu(title: "Sort by")
        for column in ExplorerSortColumn.allCases {
            let item = addItem(column.title, #selector(chooseSortColumn(_:)), to: menu)
            item.representedObject = column.rawValue
            item.state = sort.column == column ? .on : .off
        }
        menu.addItem(.separator())
        let ascending = addItem("Ascending", #selector(chooseSortDirection(_:)), to: menu)
        ascending.tag = 0
        ascending.state = sort.ascending ? .on : .off
        let descending = addItem("Descending", #selector(chooseSortDirection(_:)), to: menu)
        descending.tag = 1
        descending.state = sort.ascending ? .off : .on
        return menu
    }

    private func makeViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")
        let detailsItem = addItem("Details", #selector(chooseViewMode(_:)), to: menu)
        detailsItem.tag = 0
        detailsItem.state = mode == .details ? .on : .off
        let iconsItem = addItem("Icons", #selector(chooseViewMode(_:)), to: menu)
        iconsItem.tag = 1
        iconsItem.state = mode == .icons ? .on : .off
        return menu
    }

    @discardableResult
    private func addItem(_ title: String, _ action: Selector, to menu: NSMenu) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func addSubmenu(_ title: String, _ submenu: NSMenu, to menu: NSMenu) {
        let item = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
    }
}
