import AppKit
import HoboshellCore

extension ExplorerController {
    @objc func goBack() {
        var trial = navigationRequests.base(applied: history)
        guard trial.goBack() != nil else { return }
        commit(trial)
    }

    @objc func goForward() {
        var trial = navigationRequests.base(applied: history)
        guard trial.goForward() != nil else { return }
        commit(trial)
    }

    @objc func goUp() {
        let current = navigationRequests.base(applied: history).current
        guard current.path != "/" else { return }
        navigate(to: current.deletingLastPathComponent())
    }

    @objc func refresh() {
        statusError = nil
        reload()
    }

    func navigate(to url: URL) {
        var trial = navigationRequests.base(applied: history)
        trial.visit(url.standardizedFileURL)
        commit(trial)
    }

    func goToTyped(_ text: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let url = ExplorerPathInput.resolve(text, home: home, current: history.current) else { return }
        guard FileManager.default.fileExists(atPath: url.path) else {
            report("Cannot find \"\(url.path)\". Check the spelling and try again.")
            return
        }
        if FileEntry.isBrowsableFolder(url) {
            navigate(to: url)
        } else {
            openWithDefaultApp(url)
        }
    }

    func reload(selecting paths: Set<String>? = nil, then completion: (() -> Void)? = nil) {
        if let completion {
            reloadCompletions.append(completion)
        }
        guard !isRenaming else {
            reloadWaitsForRename = true
            return
        }
        let startedAt = ShellClock.now()
        let ticket = reads.beginReload(at: startedAt)
        let folder = history.current
        let showHidden = showsHidden
        let readSort = sort
        ioQueue.async { [weak self] in
            let result = Result { try FileEntry.contents(of: folder, showHidden: showHidden, sort: readSort) }
            DispatchQueue.main.async { [weak self] in
                self?.applyReload(result, ticket: ticket, readWith: readSort, selecting: paths, startedAt: startedAt)
            }
        }
    }

    func folderChangedOnDisk() {
        guard !reads.isChangeCovered(eventAt: watcher.lastEventAt) else { return }
        reload()
    }

    func flushPendingReload() {
        guard reloadWaitsForRename else { return }
        reloadWaitsForRename = false
        reload()
    }

    private func applyReload(
        _ result: Result<[FileEntry], Error>,
        ticket: ExplorerReadTicket,
        readWith readSort: ExplorerSort,
        selecting paths: Set<String>?,
        startedAt: UInt64
    ) {
        guard reads.accept(ticket) else { return }
        guard !isRenaming else {
            reloadWaitsForRename = true
            return
        }
        switch result {
        case .failure(let error):
            reloadCompletions.removeAll()
            handleUnreadableFolder(error)
        case .success(let entries):
            allEntries = readSort == sort ? entries : sort.apply(to: entries)
            PerfLog.took("explorer folder read of \(allEntries.count) items", since: startedAt)
            let shownAt = ShellClock.now()
            showEntries(selecting: paths ?? selectedPaths)
            PerfLog.took("explorer folder show of \(allEntries.count) items", since: shownAt)
            let completions = reloadCompletions
            reloadCompletions.removeAll()
            completions.forEach { $0() }
        }
        firstReadSettled()
    }

    private func firstReadSettled() {
        let callback = onFirstRead
        onFirstRead = nil
        callback?()
    }

    private func commit(_ trial: NavigationHistory) {
        navigationRequests.request(trial)
        let ticket = reads.beginNavigation()
        let folder = trial.current
        let showHidden = showsHidden
        let readSort = sort
        ioQueue.async { [weak self] in
            let result = Result { try FileEntry.contents(of: folder, showHidden: showHidden, sort: readSort) }
            DispatchQueue.main.async { [weak self] in
                self?.applyNavigation(result, to: trial, ticket: ticket, readWith: readSort)
            }
        }
    }

    private func applyNavigation(
        _ result: Result<[FileEntry], Error>,
        to trial: NavigationHistory,
        ticket: ExplorerReadTicket,
        readWith readSort: ExplorerSort
    ) {
        guard reads.isCurrent(ticket) else { return }
        navigationRequests.settle()
        switch result {
        case .failure(let error):
            report(error)
        case .success(let entries):
            guard reads.accept(ticket) else { return }
            reloadCompletions.removeAll()
            allEntries = readSort == sort ? entries : sort.apply(to: entries)
            history = trial
            query = ""
            toolbar.clearSearch()
            statusError = nil
            presentFolder(selecting: [])
        }
        firstReadSettled()
    }

    private func handleUnreadableFolder(_ error: Error) {
        let folder = history.current
        guard !FileManager.default.fileExists(atPath: folder.path) else {
            report(error)
            return
        }
        let fallback = ExplorerPathInput.nearestExistingFolder(from: folder, isFolder: FileEntry.isBrowsableFolder)
        navigate(to: fallback)
        report("\"\(folder.lastPathComponent)\" is no longer there. Showing \"\(fallback.lastPathComponent)\" instead.")
    }
}
