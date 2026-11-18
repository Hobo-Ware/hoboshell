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
        case .focusSearch: toolbar.searchField.focus()
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
        let startedAt = ShellClock.now()
        let contents = clipboard.read()
        guard !contents.urls.isEmpty, canWriteHere else { return }
        let folder = history.current
        let operation: TransferOperation = contents.isCut ? .move : .copy
        ioQueue.async { [weak self] in
            let result = ExplorerFileOperations.transfer(contents.urls, into: folder, operation: operation)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if contents.isCut {
                    self.clipboard.finishCut(movedTo: result.created)
                }
                self.finish(result, into: folder) {
                    PerfLog.took("explorer paste of \(contents.urls.count) items", since: startedAt)
                }
            }
        }
    }

    @objc func trashSelection() {
        let startedAt = ShellClock.now()
        let targets = selectedEntries
        guard !targets.isEmpty else { return }
        ioQueue.async { [weak self] in
            var failures: [String] = []
            for entry in targets {
                do {
                    try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
                } catch {
                    failures.append("\(entry.name): \(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.reload(selecting: []) {
                    PerfLog.took("explorer trash of \(targets.count) items", since: startedAt)
                }
                self.reportFailures(failures)
            }
        }
    }

    func trash(_ urls: [URL]) {
        let startedAt = ShellClock.now()
        TrashActions.trash(urls) { [weak self] failures in
            self?.reload(selecting: [])
            self?.reportFailures(failures)
            PerfLog.took("explorer drop of \(urls.count) items on Trash", since: startedAt)
        }
    }

    @objc func newFolder() {
        let startedAt = ShellClock.now()
        let folder = history.current
        ioQueue.async { [weak self] in
            let result = Result { try ExplorerFileOperations.createFolder(in: folder) }
            DispatchQueue.main.async { [weak self] in
                self?.finishNewFolder(result, in: folder, startedAt: startedAt)
            }
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

    func searchChanged(_ text: String) {
        query = text
        showEntries(selecting: selectedPaths)
    }

    func setMode(_ newMode: ExplorerViewMode) {
        guard newMode != mode else {
            updateSelectionState()
            return
        }
        let keep = selectedPaths
        mode = newMode
        newMode.save()
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

    func finish(_ result: ExplorerTransferResult, into folder: URL, then completion: (() -> Void)? = nil) {
        let isHere = folder.standardizedFileURL.path == history.current.path
        reload(selecting: isHere ? Set(result.created.map(\.path)) : nil, then: completion)
        reportFailures(result.failures)
    }

    private func finishNewFolder(_ result: Result<URL, Error>, in folder: URL, startedAt: UInt64) {
        switch result {
        case .failure(let error):
            report(error)
        case .success(let created):
            guard folder == history.current else {
                reload()
                return
            }
            query = ""
            toolbar.clearSearch()
            reload(selecting: [created.path]) { [weak self] in
                PerfLog.took("explorer new folder", since: startedAt)
                self?.beginRenaming(path: created.path)
            }
        }
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
