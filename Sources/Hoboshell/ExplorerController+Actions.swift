import AppKit
import HoboshellCore

extension ExplorerController {
    func perform(_ action: ExplorerAction) {
        switch action {
        case .back: goBack()
        case .forward: goForward()
        case .up: goUp()
        case .open: openSelection()
        case .rename: renameSelection()
        case .copy: copySelection()
        case .cut: cutSelection()
        case .paste: paste()
        case .selectAll: selectAllItems()
        case .trash: trashSelection()
        case .newFolder: newFolder()
        case .focusAddress: toolbar.addressBar.beginEditing()
        case .focusSearch: window?.makeFirstResponder(toolbar.searchField)
        case .quickLook: quickLook()
        case .refresh: refresh()
        case .closeWindow: window?.performClose(nil)
        }
    }

    @objc func openSelection() {
        let entries = selectedEntries
        if entries.count == 1, let only = entries.first, only.isFolder {
            navigate(to: only.url)
            return
        }
        entries.forEach { openWithDefaultApp($0.url) }
    }

    @objc func openSelectionWithDefaultApp() {
        selectedEntries.forEach { openWithDefaultApp($0.url) }
    }

    func openWithDefaultApp(_ url: URL) {
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, error in
            guard let error else { return }
            DispatchQueue.main.async {
                self?.report(error)
            }
        }
    }

    @objc func renameSelection() {
        guard let first = items.selectedIndexes.first else { return }
        items.beginRename(at: first)
    }

    @objc func copySelection() {
        writeClipboard(cut: false)
    }

    @objc func cutSelection() {
        writeClipboard(cut: true)
    }

    @objc func paste() {
        let contents = clipboard.read()
        guard !contents.urls.isEmpty, canWriteHere else { return }
        let result = ExplorerFileOperations.transfer(contents.urls, into: history.current, operation: contents.isCut ? .move : .copy)
        if contents.isCut {
            clipboard.finishCut(movedTo: result.created)
        }
        finish(result, into: history.current)
    }

    @objc func trashSelection() {
        let targets = selectedEntries
        guard !targets.isEmpty else { return }
        var failures: [String] = []
        for entry in targets {
            do {
                try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
            } catch {
                failures.append("\(entry.name): \(error.localizedDescription)")
            }
        }
        reload(selecting: [])
        reportFailures(failures)
    }

    @objc func newFolder() {
        do {
            let created = try ExplorerFileOperations.createFolder(in: history.current)
            query = ""
            toolbar.clearSearch()
            reload(selecting: [created.path])
            beginRenaming(path: created.path)
        } catch {
            report(error)
        }
    }

    func selectAllItems() {
        items.selectAll()
        updateSelectionState()
    }

    @objc func copyPath() {
        let targets = selectedEntries.map(\.url.path)
        clipboard.writeText((targets.isEmpty ? [history.current.path] : targets).joined(separator: "\n"))
        updateSelectionState()
    }

    @objc func showInFinder() {
        let urls = selectedEntries.map(\.url)
        NSWorkspace.shared.activateFileViewerSelecting(urls.isEmpty ? [history.current] : urls)
    }

    @objc func toggleHidden() {
        showsHidden.toggle()
        reload()
    }

    @objc func viewModeChanged(_ sender: NSSegmentedControl) {
        setMode(sender.selectedSegment == 0 ? .details : .icons)
    }

    @objc func chooseViewMode(_ sender: NSMenuItem) {
        setMode(sender.tag == 0 ? .details : .icons)
    }

    @objc func searchChanged(_ sender: NSSearchField) {
        query = sender.stringValue
        showEntries(selecting: selectedPaths)
    }

    func setMode(_ newMode: ExplorerViewMode) {
        guard newMode != mode else {
            updateSelectionState()
            return
        }
        let keep = selectedPaths
        mode = newMode
        applyMode()
        showEntries(selecting: keep)
        focusItems()
    }

    func applySort(_ newSort: ExplorerSort) {
        let keep = selectedPaths
        sort = newSort
        allEntries = newSort.apply(to: allEntries)
        showEntries(selecting: keep)
    }

    func finish(_ result: ExplorerTransferResult, into folder: URL) {
        let isHere = folder.standardizedFileURL.path == history.current.path
        reload(selecting: isHere ? Set(result.created.map(\.path)) : nil)
        reportFailures(result.failures)
    }

    private func writeClipboard(cut: Bool) {
        let urls = selectedEntries.map(\.url)
        guard !urls.isEmpty else { return }
        clipboard.write(urls, cut: cut)
        updateSelectionState()
    }

    private func beginRenaming(path: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let index = self.visibleEntries.firstIndex(where: { $0.url.path == path }) else { return }
            self.items.beginRename(at: index)
        }
    }
}
