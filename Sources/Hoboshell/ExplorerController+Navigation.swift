import AppKit
import HoboshellCore

extension ExplorerController {
    @objc func goBack() {
        var trial = history
        guard trial.goBack() != nil else { return }
        commit(trial)
    }

    @objc func goForward() {
        var trial = history
        guard trial.goForward() != nil else { return }
        commit(trial)
    }

    @objc func goUp() {
        guard history.current.path != "/" else { return }
        navigate(to: history.current.deletingLastPathComponent())
    }

    @objc func refresh() {
        statusError = nil
        reload()
    }

    func navigate(to url: URL) {
        var trial = history
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

    func reload(selecting paths: Set<String>? = nil) {
        guard !isRenaming else {
            reloadWaitsForRename = true
            return
        }
        let keep = paths ?? selectedPaths
        do {
            allEntries = try FileEntry.contents(of: history.current, showHidden: showsHidden, sort: sort)
        } catch {
            handleUnreadableFolder(error)
            return
        }
        showEntries(selecting: keep)
    }

    func folderChangedOnDisk() {
        reload()
    }

    func flushPendingReload() {
        guard reloadWaitsForRename else { return }
        reloadWaitsForRename = false
        reload()
    }

    private func commit(_ trial: NavigationHistory) {
        do {
            allEntries = try FileEntry.contents(of: trial.current, showHidden: showsHidden, sort: sort)
        } catch {
            report(error)
            return
        }
        history = trial
        query = ""
        toolbar.clearSearch()
        statusError = nil
        presentFolder(selecting: [])
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
