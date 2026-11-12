import AppKit
import HoboshellCore

extension ExplorerController {
    func showSortMenu(_ sender: NSView) {
        DSMenu.popUp(makeSortMenu(), below: sender)
    }

    func makeItemMenu() -> NSMenu {
        let hasSelection = !selectedEntries.isEmpty
        return DSMenu.make([
            DSMenuItem("Open", isEnabled: hasSelection) { [weak self] in self?.openSelection() },
            DSMenuItem("Open with default app", isEnabled: hasSelection) { [weak self] in
                self?.openSelectionWithDefaultApp()
            },
            DSMenu.separator(),
            DSMenuItem("Cut", isEnabled: hasSelection) { [weak self] in self?.cutSelection() },
            DSMenuItem("Copy", isEnabled: hasSelection) { [weak self] in self?.copySelection() },
            DSMenuItem("Rename", isEnabled: hasSelection) { [weak self] in self?.renameSelection() },
            DSMenuItem("Move to Trash", isEnabled: hasSelection) { [weak self] in self?.trashSelection() },
            DSMenu.separator(),
            DSMenuItem("Copy path") { [weak self] in self?.copyPath() },
            DSMenuItem("Show in Finder") { [weak self] in self?.showInFinder() },
        ])
    }

    func makeEmptyMenu() -> NSMenu {
        DSMenu.make([
            DSMenuItem("New folder", isEnabled: canWriteHere) { [weak self] in self?.newFolder() },
            DSMenuItem("Paste", isEnabled: clipboard.hasFiles && canWriteHere) { [weak self] in self?.paste() },
            DSMenu.separator(),
            DSMenu.submenu("Sort by", sortItems()),
            DSMenu.submenu("View", viewItems()),
            DSMenu.separator(),
            DSMenuItem("Refresh") { [weak self] in self?.refresh() },
        ])
    }

    private func makeSortMenu() -> NSMenu {
        DSMenu.make(sortItems(), title: "Sort by")
    }

    private func sortItems() -> [NSMenuItem] {
        let columns = ExplorerSortColumn.allCases.map { column in
            DSMenuItem(column.title, state: sort.column == column ? .on : .off) { [weak self] in
                guard let self else { return }
                self.applySort(ExplorerSort(column: column, ascending: self.sort.ascending))
            }
        }
        let directions = [
            DSMenuItem("Ascending", state: sort.ascending ? .on : .off) { [weak self] in
                guard let self else { return }
                self.applySort(ExplorerSort(column: self.sort.column, ascending: true))
            },
            DSMenuItem("Descending", state: sort.ascending ? .off : .on) { [weak self] in
                guard let self else { return }
                self.applySort(ExplorerSort(column: self.sort.column, ascending: false))
            },
        ]
        return columns + [DSMenu.separator()] + directions
    }

    private func viewItems() -> [NSMenuItem] {
        [
            DSMenuItem("Details", state: mode == .details ? .on : .off) { [weak self] in self?.setMode(.details) },
            DSMenuItem("Icons", state: mode == .icons ? .on : .off) { [weak self] in self?.setMode(.icons) },
        ]
    }
}
