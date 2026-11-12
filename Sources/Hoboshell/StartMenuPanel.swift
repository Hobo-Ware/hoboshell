import AppKit
import Carbon.HIToolbox
import HoboshellCore

enum StartMenuOpening {
    case pinned
    case allApps
    case search(String)
}

final class StartMenuPanel: NSPanel {
    private static let menuSize = NSSize(width: 640, height: 620)
    private static let recentLimit = 6
    private static let searchDelay: TimeInterval = 0.15
    private static let hiddenFunctionKeys: ClosedRange<UInt32> = 0xF700...0xF8FF

    private enum Mode {
        case pinned
        case allApps
        case search
    }

    private enum Zone: CaseIterable {
        case search
        case rail
        case main
        case footer
    }

    private let search = DSSearchField(placeholder: "Search apps, files and settings")
    private let scroll = NSScrollView()
    private let installedApps: [StartMenuApp]
    private let installedNames: [String]
    private let fileQuery = StartMenuFileQuery()
    private let recentQuery = StartMenuFileQuery()
    private var startPins: TaskbarPins
    private var recents: [URL] = []
    private var fileResults: [URL] = []
    private var query = ""
    private var mode = Mode.pinned
    private var page = StartMenuPage.empty
    private var zone = Zone.search
    private var highlight: StartPosition?
    private var hasMovedHighlight = false
    private var railIndex = 0
    private var footerIndex = 0
    private var railItems: [StartMenuItem] = []
    private var footerItems: [StartMenuItem] = []
    private var lit: [DSControl] = []
    private var pendingSearch: DispatchWorkItem?
    private var activationObserver: NSObjectProtocol?
    private var mouseMonitors: [Any] = []

    init() {
        let installed = StartMenuApps.installed()
        installedApps = installed
        installedNames = installed.map(\.name)
        startPins = StartMenuPinStore.load { StartMenuApps.app(forBundleID: $0, in: installed) != nil }
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.menuSize),
            styleMask: DSPanelStyle.styleMask,
            backing: .buffered,
            defer: false
        )
        buildContent(in: DSPanelStyle.apply(to: self, kind: .flyout))
    }

    var staysOpenForCapture = false

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    override func orderOut(_ sender: Any?) {
        guard !staysOpenForCapture else { return }
        stopWatching()
        pendingSearch?.cancel()
        fileQuery.stop()
        recentQuery.stop()
        super.orderOut(sender)
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_Tab:
            cycleZone(forward: !event.modifierFlags.contains(.shift))
        case kVK_Escape:
            orderOut(nil)
        case kVK_UpArrow:
            move(.up)
        case kVK_DownArrow:
            move(.down)
        case kVK_LeftArrow:
            move(.left)
        case kVK_RightArrow:
            move(.right)
        case kVK_Return, kVK_ANSI_KeypadEnter, kVK_Space:
            activateCurrent()
        default:
            if !typeIntoSearch(event) {
                super.keyDown(with: event)
            }
        }
    }

    func toggle(origin: (NSSize) -> NSPoint) {
        if isVisible {
            orderOut(nil)
            return
        }
        present(origin: origin, opening: .pinned)
    }

    func present(origin: (NSSize) -> NSPoint, opening: StartMenuOpening) {
        reset(for: opening)
        setFrameOrigin(origin(frame.size))
        if staysOpenForCapture {
            orderFrontRegardless()
        } else {
            makeKeyAndOrderFront(nil)
        }
        startWatching()
        enter(.search)
        loadRecents()
    }

    private func reset(for opening: StartMenuOpening) {
        hasMovedHighlight = false
        highlight = nil
        zone = .search
        fileResults = []
        switch opening {
        case .pinned:
            query = ""
            mode = .pinned
        case .allApps:
            query = ""
            mode = .allApps
        case .search(let text):
            query = text.trimmingCharacters(in: .whitespaces)
            mode = query.isEmpty ? .pinned : .search
        }
        search.stringValue = query
        rebuildPage(resetScroll: true)
        if mode == .search {
            highlight = defaultHighlight
            scheduleFileSearch(immediately: true)
        }
    }

    private func buildContent(in background: DSCard) {
        search.onChange = { [weak self] text in
            self?.queryChanged(text)
        }
        search.onSubmit = { [weak self] _ in
            self?.activateHighlight()
        }
        search.onCancel = { [weak self] in
            self?.orderOut(nil)
        }
        search.onCommand = { [weak self] command in
            self?.handleSearchCommand(command) ?? false
        }
        search.translatesAutoresizingMaskIntoConstraints = false

        railItems = makeRailItems()
        let rail = NSStackView(views: railItems.map(\.view))
        rail.orientation = .vertical
        rail.alignment = .centerX
        rail.spacing = DSSpacing.xs
        rail.setHuggingPriority(.required, for: .horizontal)
        rail.translatesAutoresizingMaskIntoConstraints = false

        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        footerItems = makeFooterItems()
        let spacer = NSView()
        spacer.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        let footer = NSStackView(views: [footerItems[0].view, spacer, footerItems[1].view])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.translatesAutoresizingMaskIntoConstraints = false
        let divider = DSDivider()

        for view in [search, rail, scroll, divider, footer] {
            background.addSubview(view)
        }
        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: background.topAnchor, constant: DSSpacing.m),
            search.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            search.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            rail.topAnchor.constraint(equalTo: search.bottomAnchor, constant: DSSpacing.s),
            rail.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            scroll.topAnchor.constraint(equalTo: search.bottomAnchor, constant: DSSpacing.s),
            scroll.leadingAnchor.constraint(equalTo: rail.trailingAnchor, constant: DSSpacing.s),
            scroll.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            scroll.bottomAnchor.constraint(equalTo: divider.topAnchor, constant: -DSSpacing.s),
            divider.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            divider.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            divider.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -DSSpacing.s),
            footer.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: DSSpacing.m),
            footer.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -DSSpacing.m),
            footer.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -DSSpacing.m),
        ])
        rebuildPage()
    }

    private func makeRailItems() -> [StartMenuItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let places: [(HoboIcon, String, URL)] = [
            (.home, "Home", home),
            (.documents, "Documents", home.appendingPathComponent("Documents")),
            (.downloads, "Downloads", home.appendingPathComponent("Downloads")),
            (.pictures, "Pictures", home.appendingPathComponent("Pictures")),
        ]
        var items = places.map { icon, name, folder in
            railItem(icon, tip: name) { [weak self] in
                self?.orderOut(nil)
                ExplorerWindow.open(at: folder)
            }
        }
        items.append(railItem(.settings, tip: "Settings") { [weak self] in
            self?.orderOut(nil)
            self?.openSystemSettings()
        })
        return items
    }

    private func railItem(_ icon: HoboIcon, tip: String, action: @escaping () -> Void) -> StartMenuItem {
        let button = DSButton(image: icon.image(side: DSIconSize.toolbar), height: .regular, tip: tip)
        button.onPress = action
        return StartMenuItem(view: button, activate: action)
    }

    private func makeFooterItems() -> [StartMenuItem] {
        let avatar = DSAvatar(side: DSIconSize.toolbar, image: StartMenuSystem.userPicture())
        let user = DSButton(
            views: [avatar, DSLabel(StartMenuSystem.userName)],
            height: .regular,
            alignment: .leading
        )
        user.setAccessibilityLabel(StartMenuSystem.userName)
        let power = DSButton(symbol: "power", tip: "Power")
        user.onPress = { [weak self, weak user] in
            guard let self, let user else { return }
            DSMenu.popUp(self.userMenu(), below: user)
        }
        power.onPress = { [weak self, weak power] in
            guard let self, let power else { return }
            DSMenu.popUp(self.powerMenu(), below: power)
        }
        return [
            StartMenuItem(view: user, activate: user.activate),
            StartMenuItem(view: power, activate: power.activate),
        ]
    }

    private func userMenu() -> NSMenu {
        DSMenu.make([
            DSMenuItem("Lock screen", symbol: "lock") { [weak self] in self?.runSession(StartMenuSystem.lockScreen) },
            DSMenuItem("Sign out", symbol: "rectangle.portrait.and.arrow.right") { [weak self] in
                self?.runSession(StartMenuSystem.signOut)
            },
        ])
    }

    private func powerMenu() -> NSMenu {
        DSMenu.make([
            DSMenuItem("Sleep", symbol: "moon.zzz") { [weak self] in self?.runSession(StartMenuSystem.sleep) },
            DSMenuItem("Restart", symbol: "arrow.clockwise") { [weak self] in self?.runSession(StartMenuSystem.restart) },
            DSMenuItem("Shut down", symbol: "power") { [weak self] in self?.runSession(StartMenuSystem.shutDown) },
        ])
    }

    private func runSession(_ action: () throws -> Void) {
        orderOut(nil)
        do {
            try action()
        } catch {
            DSDialog.showError(title: "Could not complete the request", message: error.localizedDescription)
        }
    }

    private func makeActions() -> StartMenuActions {
        StartMenuActions(
            open: { [weak self] in self?.open($0) },
            openFile: { [weak self] in self?.openFile($0) },
            openSetting: { [weak self] in self?.openSetting($0) },
            showAllApps: { [weak self] in self?.setMode(.allApps) },
            showPinned: { [weak self] in self?.setMode(.pinned) },
            appMenu: { [weak self] app in StartMenuLazyMenu { self?.appMenuItems(for: app) ?? [] } },
            fileMenu: { [weak self] url in StartMenuLazyMenu { self?.fileMenuItems(for: url) ?? [] } },
            movePin: { [weak self] in self?.movePin($0, before: $1) }
        )
    }

    private func appMenuItems(for app: StartMenuApp) -> [NSMenuItem] {
        let identifier = app.bundleID
        let isStartPinned = identifier.map(startPins.contains) ?? false
        let isTaskbarPinned = identifier.map(TaskbarPinStore.loadPins().contains) ?? false
        return [
            DSMenuItem("Open", symbol: "arrow.up.forward.app") { [weak self] in self?.open(app) },
            DSMenu.separator(),
            DSMenuItem(
                isStartPinned ? "Unpin from Start" : "Pin to Start",
                symbol: isStartPinned ? "pin.slash" : "pin",
                isEnabled: identifier != nil
            ) { [weak self] in
                guard let identifier else { return }
                self?.toggleStartPin(identifier)
            },
            DSMenuItem(
                isTaskbarPinned ? "Unpin from taskbar" : "Pin to taskbar",
                symbol: "dock.rectangle",
                isEnabled: identifier != nil
            ) {
                guard let identifier else { return }
                let pins = TaskbarPinStore.loadPins()
                TaskbarPinStore.save(pins.contains(identifier) ? pins.removing(identifier) : pins.adding(identifier))
            },
            DSMenu.separator(),
            DSMenuItem("Show in Files", symbol: "folder") { [weak self] in
                self?.showInFiles(app.url.deletingLastPathComponent())
            },
        ]
    }

    private func fileMenuItems(for url: URL) -> [NSMenuItem] {
        [
            DSMenuItem("Open", symbol: "arrow.up.forward.app") { [weak self] in self?.openFile(url) },
            DSMenuItem("Show in Files", symbol: "folder") { [weak self] in
                self?.showInFiles(url.deletingLastPathComponent())
            },
        ]
    }

    private func toggleStartPin(_ identifier: String) {
        startPins = startPins.contains(identifier) ? startPins.removing(identifier) : startPins.adding(identifier)
        StartMenuPinStore.save(startPins)
        rebuildPage()
    }

    private func movePin(_ identifier: String, before anchor: String?) {
        startPins = startPins.moving(identifier, before: anchor)
        StartMenuPinStore.save(startPins)
        rebuildPage()
    }

    private func open(_ app: StartMenuApp) {
        orderOut(nil)
        NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            guard let error else { return }
            DispatchQueue.main.async { DSDialog.showError(error) }
        }
    }

    private func openFile(_ url: URL) {
        orderOut(nil)
        if !NSWorkspace.shared.open(url) {
            DSDialog.showError(title: "Could not open \(url.lastPathComponent)", message: "No app could open this file.")
        }
    }

    private func openSetting(_ pane: StartSettingsPane) {
        orderOut(nil)
        guard let url = URL(string: pane.address), NSWorkspace.shared.open(url) else {
            DSDialog.showError(title: "Could not open \(pane.name)", message: "System Settings did not accept the request.")
            return
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:"), NSWorkspace.shared.open(url) else {
            DSDialog.showError(title: "Could not open Settings", message: "System Settings did not accept the request.")
            return
        }
    }

    private func showInFiles(_ folder: URL) {
        orderOut(nil)
        ExplorerWindow.open(at: folder)
    }

    private func setMode(_ new: Mode) {
        mode = new
        hasMovedHighlight = false
        rebuildPage(resetScroll: true)
        highlight = defaultHighlight
        refreshHighlight()
    }

    private func queryChanged(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed != query else { return }
        query = trimmed
        let previous = mode
        if trimmed.isEmpty {
            pendingSearch?.cancel()
            fileQuery.stop()
            fileResults = []
            mode = .pinned
        } else {
            mode = .search
            scheduleFileSearch(immediately: false)
        }
        if previous != .search || mode != .search {
            hasMovedHighlight = false
        }
        rebuildPage(resetScroll: true)
        highlight = hasMovedHighlight ? validHighlight : defaultHighlight
        refreshHighlight()
    }

    private func scheduleFileSearch(immediately: Bool) {
        pendingSearch?.cancel()
        guard StartResults.allowsFileSearch(for: query) else {
            fileResults = []
            return
        }
        let text = query
        let work = DispatchWorkItem { [weak self] in
            self?.fileQuery.search(name: text) { [weak self] urls in
                self?.receiveFiles(urls, for: text)
            }
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (immediately ? 0 : Self.searchDelay), execute: work)
    }

    private func receiveFiles(_ urls: [URL], for text: String) {
        guard text == query, mode == .search else { return }
        fileResults = StartNameMatch.rank(query: text, in: urls.map(\.lastPathComponent)).map { urls[$0] }
        rebuildPage()
        highlight = hasMovedHighlight ? validHighlight : defaultHighlight
        refreshHighlight()
    }

    private func loadRecents() {
        recentQuery.recent(limit: Self.recentLimit) { [weak self] urls in
            guard let self else { return }
            self.recents = urls
            guard self.mode == .pinned else { return }
            self.rebuildPage()
            self.highlight = self.validHighlight
            self.refreshHighlight()
        }
    }

    private var visibleFiles: [URL] {
        let names = fileResults.map(\.lastPathComponent)
        return StartNameMatch.rank(query: query, in: names).map { fileResults[$0] }
    }

    private func makePage() -> StartMenuPage {
        let actions = makeActions()
        switch mode {
        case .pinned:
            let pinned = startPins.ids.compactMap { StartMenuApps.app(forBundleID: $0, in: installedApps) }
            return StartMenuPages.pinned(apps: pinned, recents: recents, actions: actions)
        case .allApps:
            return StartMenuPages.allApps(apps: installedApps, actions: actions)
        case .search:
            let apps = StartNameMatch.rank(query: query, in: installedNames).map { installedApps[$0] }
            return StartMenuPages.search(
                query: query, apps: apps, files: visibleFiles, settings: StartSettingsPanes.matches(query: query), actions: actions
            )
        }
    }

    private func rebuildPage(resetScroll: Bool = false) {
        let offset = resetScroll ? .zero : scroll.contentView.bounds.origin
        page = makePage()
        let document = DSFlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        DSPanelStyle.pin(page.view, to: document, inset: DSSpacing.xs)
        scroll.documentView = document
        let clip = scroll.contentView
        NSLayoutConstraint.activate([
            document.topAnchor.constraint(equalTo: clip.topAnchor),
            document.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
        ])
        document.layoutSubtreeIfNeeded()
        clip.scroll(to: clip.constrainBoundsRect(NSRect(origin: offset, size: clip.bounds.size)).origin)
        scroll.reflectScrolledClipView(clip)
    }

    private var defaultHighlight: StartPosition? {
        mode == .search ? StartNavigation.first(in: page.sections) : (zone == .main ? page.entry : nil)
    }

    private var validHighlight: StartPosition? {
        guard let highlight, page.item(at: highlight) != nil else { return defaultHighlight }
        return highlight
    }

    private func refreshHighlight() {
        lit.forEach { $0.isSelected = false }
        lit = []
        let target: DSControl?
        switch zone {
        case .search:
            target = mode == .search ? highlight.flatMap(page.item(at:))?.view : nil
        case .rail:
            target = railItems[railIndex].view
        case .main:
            target = highlight.flatMap(page.item(at:))?.view
        case .footer:
            target = footerItems[footerIndex].view
        }
        guard let target else { return }
        target.isSelected = true
        lit = [target]
        if zone == .main || zone == .search {
            target.scrollToVisible(target.bounds)
        }
    }

    private func enter(_ new: Zone) {
        zone = new
        switch new {
        case .search:
            search.focus()
            if mode != .search {
                highlight = nil
            }
        case .rail:
            makeFirstResponder(nil)
            railIndex = 0
        case .main:
            makeFirstResponder(nil)
            highlight = validHighlight ?? page.entry
        case .footer:
            makeFirstResponder(nil)
            footerIndex = 0
        }
        refreshHighlight()
    }

    private func cycleZone(forward: Bool) {
        let zones = Zone.allCases.filter { $0 != .main || page.hasItems }
        guard let index = zones.firstIndex(of: zone) else { return }
        let step = forward ? 1 : zones.count - 1
        enter(zones[(index + step) % zones.count])
    }

    private func move(_ direction: StartDirection) {
        switch zone {
        case .search:
            break
        case .rail:
            railIndex = clamped(railIndex + (direction == .down ? 1 : direction == .up ? -1 : 0), railItems.count)
        case .main:
            moveHighlight(direction)
            return
        case .footer:
            footerIndex = clamped(footerIndex + (direction == .right ? 1 : direction == .left ? -1 : 0), footerItems.count)
        }
        refreshHighlight()
    }

    private func clamped(_ index: Int, _ count: Int) -> Int {
        min(max(index, 0), count - 1)
    }

    private func moveHighlight(_ direction: StartDirection) {
        guard let current = highlight else {
            highlight = defaultHighlight ?? page.entry
            refreshHighlight()
            return
        }
        let next = StartNavigation.move(current, direction, in: page.sections)
        guard next != current else { return }
        hasMovedHighlight = true
        highlight = next
        refreshHighlight()
    }

    private func handleSearchCommand(_ command: Selector) -> Bool {
        switch command {
        case #selector(NSResponder.moveDown(_:)):
            if mode == .search {
                moveHighlight(.down)
            } else if page.hasItems {
                enter(.main)
            }
            return true
        case #selector(NSResponder.moveUp(_:)):
            guard mode == .search else { return false }
            moveHighlight(.up)
            return true
        case #selector(NSResponder.insertTab(_:)):
            cycleZone(forward: true)
            return true
        case #selector(NSResponder.insertBacktab(_:)):
            cycleZone(forward: false)
            return true
        default:
            return false
        }
    }

    private func activateHighlight() {
        highlight.flatMap(page.item(at:))?.activate()
    }

    private func activateCurrent() {
        switch zone {
        case .search, .main:
            activateHighlight()
        case .rail:
            railItems[railIndex].activate()
        case .footer:
            footerItems[footerIndex].activate()
        }
    }

    private func typeIntoSearch(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
              let characters = event.characters, !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({
                  !CharacterSet.controlCharacters.contains($0) && !Self.hiddenFunctionKeys.contains($0.value)
              })
        else { return false }
        enter(.search)
        guard let editor = search.field.currentEditor() as? NSTextView else { return true }
        editor.selectedRange = NSRange(location: (editor.string as NSString).length, length: 0)
        editor.insertText(characters, replacementRange: NSRange(location: NSNotFound, length: 0))
        return true
    }

    private func startWatching() {
        stopWatching()
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard app?.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
            self?.orderOut(nil)
        }
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let outside = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self] _ in
            self?.orderOut(nil)
        }) {
            mouseMonitors.append(outside)
        }
        let onDesktop = NSEvent.addLocalMonitorForEvents(matching: clicks) { [weak self] event in
            if event.window is DesktopWindow {
                self?.orderOut(nil)
            }
            return event
        }
        if let onDesktop {
            mouseMonitors.append(onDesktop)
        }
    }

    private func stopWatching() {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = nil
        mouseMonitors.forEach(NSEvent.removeMonitor)
        mouseMonitors = []
    }
}
