import AppKit
import HoboshellCore

final class ExplorerController: NSObject {
    weak var window: ExplorerWindow?

    var history: NavigationHistory
    var allEntries: [FileEntry] = []
    var visibleEntries: [FileEntry] = []
    var sort = ExplorerSort.standard
    var query = ""
    var showsHidden = false
    var mode = ExplorerViewMode.saved
    var typeAhead = ExplorerTypeAhead()
    var isRenaming = false
    var reloadWaitsForRename = false
    var isReloading = false
    var statusError: String?

    let sidebar = ExplorerSidebarView()
    private var iconPackObserver: NSObjectProtocol?
    let details = ExplorerDetailsView()
    let icons = ExplorerIconsView()
    let statusLabel = DSLabel(style: .caption, color: DSColor.dimText)
    let watcher = ExplorerFolderWatcher()
    let clipboard = ExplorerClipboard.shared

    lazy var toolbar = ExplorerToolbar(target: self)
    lazy var commandBar = ExplorerCommandBar(target: self)
    lazy var contentView = ExplorerContentView(
        toolbar: toolbar.view,
        commandBar: commandBar.view,
        sidebar: sidebar,
        items: [details, icons],
        status: statusLabel
    )

    var items: ExplorerItemsView {
        mode == .details ? details : icons
    }

    var currentFolder: URL {
        history.current
    }

    init(folder: URL) {
        history = NavigationHistory(start: folder.standardizedFileURL)
        super.init()
    }

    func start() {
        details.itemsDelegate = self
        icons.itemsDelegate = self
        iconPackObserver = NotificationCenter.default.addObserver(
            forName: IconPack.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.sidebar.reload()
            self?.reload()
        }
        sidebar.onSelect = { [weak self] url in
            self?.navigate(to: url)
        }
        let address = toolbar.addressBar
        address.onNavigate = { [weak self] url in
            self?.navigate(to: url)
        }
        address.onSubmit = { [weak self] text in
            self?.goToTyped(text)
        }
        address.onFinish = { [weak self] in
            self?.focusItems()
        }
        watcher.onChange = { [weak self] in
            self?.folderChangedOnDisk()
        }
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        applyMode()
        do {
            allEntries = try FileEntry.contents(of: history.current, showHidden: showsHidden, sort: sort)
        } catch {
            report(error)
        }
        presentFolder(selecting: [])
    }

    func stop() {
        watcher.stop()
    }

    func windowBecameKey() {
        reload()
        updateSelectionState()
    }

    func focusItems() {
        items.focus()
    }

    var selectedEntries: [FileEntry] {
        items.selectedIndexes.sorted().compactMap { visibleEntries.indices.contains($0) ? visibleEntries[$0] : nil }
    }

    var selectedPaths: Set<String> {
        Set(selectedEntries.map(\.url.path))
    }

    var canWriteHere: Bool {
        FileManager.default.isWritableFile(atPath: history.current.path)
    }

    func presentFolder(selecting paths: Set<String>) {
        let folder = history.current
        watcher.watch(folder)
        window?.title = folder.path == "/" ? Breadcrumbs.rootName : folder.lastPathComponent
        toolbar.addressBar.show(folder)
        sidebar.highlight(folder)
        toolbar.update(canGoBack: history.canGoBack, canGoForward: history.canGoForward, canGoUp: folder.path != "/")
        showEntries(selecting: paths)
    }

    func showEntries(selecting paths: Set<String>) {
        visibleEntries = ExplorerFilter.apply(to: allEntries, query: query)
        isReloading = true
        items.show(visibleEntries, sort: sort, selecting: paths)
        isReloading = false
        updateSelectionState()
    }

    func updateSelectionState() {
        let selection = selectedEntries
        commandBar.update(
            selectionCount: selection.count,
            canPaste: clipboard.hasFiles,
            canWrite: canWriteHere,
            showsHidden: showsHidden,
            mode: mode
        )
        statusLabel.stringValue = statusError ?? ExplorerStatusText.text(itemCount: visibleEntries.count, selection: selection)
        statusLabel.textColor = statusError == nil ? DSColor.dimText : DSColor.danger
        reloadQuickLook()
    }

    func report(_ error: Error) {
        report(error.localizedDescription)
    }

    func report(_ message: String) {
        statusError = message
        statusLabel.stringValue = message
        statusLabel.textColor = DSColor.danger
    }

    func reportFailures(_ failures: [String]) {
        guard let first = failures.first else { return }
        report(failures.count == 1 ? first : "\(first) (\(failures.count - 1) more failed)")
    }

    func applyMode() {
        details.isHidden = mode != .details
        icons.isHidden = mode != .icons
    }
}
