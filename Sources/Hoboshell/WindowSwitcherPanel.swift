import AppKit
import HoboshellCore

final class WindowSwitcherPanel: NSPanel {
    private static let screenShare: CGFloat = 0.8
    private static let padding = DSSpacing.m
    private static let tileSpacing = DSSpacing.s

    var staysOpenForCapture = false
    var onCommit: ((ShellWindow) -> Void)?
    var onQuit: ((ShellWindow) -> Void)?
    var onClose: ((ShellWindow) -> Void)?
    var onEnd: (() -> Void)?

    private let scroll = NSScrollView()
    private let document = DSFlippedView()
    private var scrollWidth: NSLayoutConstraint?
    private var scrollHeight: NSLayoutConstraint?
    private var documentHeight: NSLayoutConstraint?
    private var windows: [ShellWindow] = []
    private var tiles: [Int: DSSwitcherTile] = [:]
    private var tileOrder: [Int] = []
    private var selected: Int?
    private var columns = 1
    private var iconObserver: NSObjectProtocol?
    private var holding: SwitcherModifier?
    private var screenInUse: NSScreen?
    private var modifierMonitors: [Any] = []

    private(set) var isShowing = false

    init() {
        super.init(contentRect: .zero, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: true)
        let background = DSPanelStyle.apply(to: self, kind: .flyout, level: .popUpMenu)

        document.translatesAutoresizingMaskIntoConstraints = false

        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.documentView = document
        DSPanelStyle.pin(scroll, to: background, inset: Self.padding)
        let clip = scroll.contentView
        scrollWidth = scroll.widthAnchor.constraint(equalToConstant: DSSwitcherTile.size.width)
        scrollHeight = scroll.heightAnchor.constraint(equalToConstant: DSSwitcherTile.size.height)
        documentHeight = document.heightAnchor.constraint(equalToConstant: DSSwitcherTile.size.height)
        NSLayoutConstraint.activate([
            document.topAnchor.constraint(equalTo: clip.topAnchor),
            document.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
        ] + [scrollWidth, scrollHeight, documentHeight].compactMap { $0 })
        iconObserver = NotificationCenter.default.addObserver(
            forName: AppIcons.didLoad, object: nil, queue: .main
        ) { [weak self] _ in
            guard self?.isShowing == true else { return }
            self?.reconcile()
        }
    }

    deinit {
        if let iconObserver {
            NotificationCenter.default.removeObserver(iconObserver)
        }
    }

    override var canBecomeKey: Bool { false }

    func begin(windows candidates: [ShellWindow], holding: SwitcherModifier?, forward: Bool, on screen: NSScreen) {
        guard let start = SwitcherSelection.initial(count: candidates.count, forward: forward) else {
            onEnd?()
            return
        }
        windows = candidates
        selected = start
        self.holding = holding
        screenInUse = screen
        isShowing = true
        reconcile()
        orderFrontRegardless()
        refreshPictures()
        if let holding {
            guard Self.isHeld(holding) else {
                finish(commit: true)
                return
            }
            watchForRelease(of: holding)
        }
    }

    func update(windows fresh: [ShellWindow]) {
        guard isShowing else { return }
        let order = WindowRecency.keepingOrder(of: windows.map(\.id), among: fresh.map(\.id))
        let byID = Dictionary(fresh.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let ordered = order.compactMap { byID[$0] }
        guard !ordered.isEmpty else {
            finish(commit: false)
            return
        }
        let selectedID = selected.flatMap { windows.indices.contains($0) ? windows[$0].id : nil }
        windows = ordered
        selected = ordered.firstIndex { $0.id == selectedID } ?? min(selected ?? 0, ordered.count - 1)
        reconcile()
    }

    func apply(_ action: SwitcherAction) {
        guard isShowing, let current = selected, windows.indices.contains(current) else { return }
        switch action {
        case .advance(let forward):
            select(SwitcherSelection.step(from: current, forward: forward, count: windows.count))
        case .move(let direction):
            select(SwitcherGrid.move(from: current, direction, count: windows.count, columns: columns))
        case .cancel:
            finish(commit: false)
        case .commit:
            finish(commit: true)
        case .quitSelected:
            let window = windows[current]
            onQuit?(window)
            remove { $0.app.processIdentifier == window.app.processIdentifier }
        case .closeSelected:
            let window = windows[current]
            onClose?(window)
            remove { $0.id == window.id }
        case .open:
            break
        }
    }

    func finish(commit: Bool) {
        guard isShowing, !staysOpenForCapture else { return }
        isShowing = false
        modifierMonitors.forEach(NSEvent.removeMonitor)
        modifierMonitors = []
        orderOut(nil)
        let chosen = selected.flatMap { windows.indices.contains($0) ? windows[$0] : nil }
        windows = []
        selected = nil
        onEnd?()
        if commit, let chosen {
            onCommit?(chosen)
        }
    }

    private static func isHeld(_ modifier: SwitcherModifier) -> Bool {
        NSEvent.modifierFlags.contains(modifier == .command ? .command : .option)
    }

    private func watchForRelease(of modifier: SwitcherModifier) {
        let commitWhenReleased: (NSEvent) -> Void = { [weak self] event in
            if !event.modifierFlags.contains(modifier == .command ? .command : .option) {
                self?.finish(commit: true)
            }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: commitWhenReleased) {
            modifierMonitors.append(global)
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            commitWhenReleased(event)
            return event
        }
        if let local {
            modifierMonitors.append(local)
        }
    }

    private func select(_ index: Int?) {
        guard let index, windows.indices.contains(index) else { return }
        selected = index
        refreshSelection()
    }

    private func remove(where isGone: (ShellWindow) -> Bool) {
        let selectedID = selected.map { windows[$0].id }
        let remaining = windows.filter { !isGone($0) }
        guard !remaining.isEmpty else {
            finish(commit: false)
            return
        }
        let previous = selected ?? 0
        windows = remaining
        selected = remaining.firstIndex { $0.id == selectedID } ?? min(previous, remaining.count - 1)
        reconcile()
    }

    private func reconcile() {
        guard let screen = screenInUse else { return }
        let tileSize = DSSwitcherTile.size
        let limit = NSSize(width: screen.frame.width * Self.screenShare, height: screen.frame.height * Self.screenShare)
        let layout = SwitcherGrid.layout(
            count: windows.count,
            tile: tileSize,
            spacing: Self.tileSpacing,
            available: NSSize(width: limit.width - Self.padding * 2, height: limit.height - Self.padding * 2)
        )
        columns = max(layout.columns, 1)

        let diff = ListDiff(old: tileOrder, new: windows.map(\.id))
        for id in diff.removed {
            tiles.removeValue(forKey: id)?.removeFromSuperview()
        }
        for (index, window) in windows.enumerated() {
            let tile = tiles[window.id] ?? makeTile(for: window)
            tile.show(title: window.title, icon: AppIcons.shared.image(forPath: window.app.bundleURL?.path))
            tile.frame = NSRect(
                x: CGFloat(index % columns) * (tileSize.width + Self.tileSpacing),
                y: CGFloat(index / columns) * (tileSize.height + Self.tileSpacing),
                width: tileSize.width,
                height: tileSize.height
            )
        }
        tileOrder = windows.map(\.id)

        let width = CGFloat(layout.columns) * tileSize.width + CGFloat(layout.columns - 1) * Self.tileSpacing
        let height = CGFloat(layout.visibleRows) * tileSize.height + CGFloat(layout.visibleRows - 1) * Self.tileSpacing
        let rows = max(layout.rows, 1)
        documentHeight?.constant = CGFloat(rows) * tileSize.height + CGFloat(rows - 1) * Self.tileSpacing
        scrollWidth?.constant = width
        scrollHeight?.constant = height
        scroll.hasVerticalScroller = layout.rows > layout.visibleRows
        scroll.autohidesScrollers = true
        let panelSize = NSSize(width: width + Self.padding * 2, height: height + Self.padding * 2)
        let target = NSRect(
            x: screen.frame.midX - panelSize.width / 2,
            y: screen.frame.midY - panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        if frame != target {
            setFrame(target, display: true)
        }
        refreshSelection()
    }

    private func makeTile(for window: ShellWindow) -> DSSwitcherTile {
        let tile = DSSwitcherTile()
        let id = window.id
        tile.onPress = { [weak self] in
            guard let self, let index = self.windows.firstIndex(where: { $0.id == id }) else { return }
            self.select(index)
            self.finish(commit: true)
        }
        if let remembered = WindowPreview.cached(id) {
            tile.show(picture: remembered)
        }
        document.addSubview(tile)
        tiles[id] = tile
        capturePicture(for: window, in: tile)
        return tile
    }

    private func refreshPictures() {
        for window in windows {
            if let tile = tiles[window.id] {
                capturePicture(for: window, in: tile)
            }
        }
    }

    private func capturePicture(for window: ShellWindow, in tile: DSSwitcherTile) {
        let request = PreviewRequest(
            windowID: window.id,
            pid: window.app.processIdentifier,
            title: window.title,
            isMinimized: window.isMinimized
        )
        WindowPreview.askForAccessOnce()
        WindowPreview.capture(request, limit: DSSwitcherTile.pictureSize) { [weak self, weak tile] image in
            guard let self, let tile, self.tiles[window.id] === tile, let image else { return }
            tile.show(picture: image)
        }
    }

    private func refreshSelection() {
        for (index, window) in windows.enumerated() {
            tiles[window.id]?.isSelected = index == selected
        }
        if let selected, windows.indices.contains(selected), let tile = tiles[windows[selected].id] {
            tile.scrollToVisible(tile.bounds)
        }
    }
}
