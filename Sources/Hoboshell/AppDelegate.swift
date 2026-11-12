import AppKit
import Carbon.HIToolbox
import HoboshellCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let windowRefreshInterval: TimeInterval = 1.5
    private static let windowEventSettleDelay: TimeInterval = 0.15
    private static let neverInTray = ["com.apple.finder"]
    private static let savedVariantKey = "ShellVariant"
    private static let snapLog = Logger(subsystem: "dev.hoboware.hoboshell", category: "snap")

    private let tracker = AppTracker()
    private let catalog = WindowCatalog()
    private let windowEvents = WindowEventObserver()
    private let dockBadges = DockBadges()
    private var backgroundApps = BackgroundApps()
    private let showDesktop = TaskbarShowDesktop()
    private let nudger = WindowNudger()
    private let hidesSystemUI = ProcessInfo.processInfo.environment["HOBOSHELL_HIDE_SYSTEM_UI"] == "1"
    private var variant = ShellVariant.resolve(
        arguments: CommandLine.arguments,
        saved: UserDefaults.standard.string(forKey: AppDelegate.savedVariantKey)
    )
    private var dockReservation = DockReservation.off
    private var chrome: ShellChrome?
    private var desktop: DesktopWindow?
    private var startMenu: StartMenuPanel?
    private var switcher: SwitcherController?
    private var windowRefreshTimer: Timer?
    private var signalSources: [DispatchSourceSignal] = []
    private var badges: [String: String] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateCleanlyOnSignals()
        if !hidesSystemUI && !SystemChrome.isWanted && SystemChrome.isActive {
            SystemChrome.restore()
        }
        Accessibility.requestTrust()
        MainMenu.install()

        startMenu = StartMenuPanel()
        switcher = SwitcherController(catalog: catalog) { [weak self] in
            self?.appsWithWindows ?? []
        }
        switcher?.start()
        buildShell()

        tracker.onChange = { [weak self] in
            self?.refreshTaskbar()
        }
        tracker.onUserActivation = { [weak self] in
            self?.showDesktop.userActivatedApp()
        }
        tracker.start()
        windowEvents.onDestroyed = { [weak self] element in
            self?.catalog.noteDestroyed(element)
        }
        windowEvents.onChange = { [weak self] in
            self?.refreshTaskbar()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.windowEventSettleDelay) {
                self?.refreshTaskbar()
            }
        }
        windowEvents.onGeometryChange = { [weak self] window in
            self?.nudger.windowChanged(window)
        }
        windowRefreshTimer = Timer.scheduledTimer(withTimeInterval: Self.windowRefreshInterval, repeats: true) { [weak self] _ in
            self?.refreshBadges()
            self?.refreshTaskbar()
        }
        registerHotKeys()
        openRequestedWindows()
        if hidesSystemUI || SystemChrome.isWanted {
            engageDock()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dockWantedChanged),
            name: SystemChrome.wantedDidChange,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if SystemChrome.isActive {
            SystemChrome.restore()
        }
    }

    private var appsWithWindows: [NSRunningApplication] {
        tracker.taskbarApps + [.current]
    }

    private func buildShell() {
        guard let screen = shellScreen else { return }
        chrome?.dismiss()
        desktop?.orderOut(nil)
        startMenu?.orderOut(nil)

        let layout = ShellLayout(variant: variant, screen: screen, dockReservation: reservation(on: screen))
        nudger.barFrame = variant == .bottomTaskbar ? layout.bar : nil
        let desktop = DesktopWindow(screen: screen, reserved: layout.reserved, color: variant.desktopColor)
        desktop.orderFront(nil)
        self.desktop = desktop

        let switchTitle = "Switch to \(variant.other.displayName)"
        let chrome: ShellChrome = variant == .bottomTaskbar
            ? TaskbarPanel(layout: layout, switchTitle: switchTitle)
            : TopBarDockChrome(layout: layout, switchTitle: switchTitle)
        chrome.actions = ShellActions(
            onStart: { [weak self] in
                self?.toggleStartMenu()
            },
            onFiles: {
                ExplorerWindow.open(at: FileManager.default.homeDirectoryForCurrentUser)
            },
            onShowDesktop: { [weak self] in
                guard let self else { return }
                self.showDesktop.toggle(apps: self.tracker.taskbarApps)
            },
            onSwitchVariant: { [weak self] in
                self?.switchVariant()
            }
        )
        chrome.show()
        self.chrome = chrome
        refreshTaskbar()
    }

    private var shellScreen: NSScreen? {
        dockReservation.isOn ? NSScreen.screens.first : NSScreen.main
    }

    private func reservation(on screen: NSScreen) -> DockReservation {
        screen == NSScreen.screens.first ? dockReservation : .off
    }

    private func switchVariant() {
        variant = variant.other
        UserDefaults.standard.set(variant.rawValue, forKey: Self.savedVariantKey)
        dockReservation = .off
        buildShell()
        if SystemChrome.isActive {
            engageDock()
        }
    }

    private func engageDock() {
        SystemChrome.engage(variant: variant) { [weak self] reservation in
            self?.dockReservation = reservation
            self?.buildShell()
        }
    }

    private func openRequestedWindows() {
        for target in ShowTarget.parse(arguments: CommandLine.arguments) {
            switch target {
            case .start:
                showStartMenu(.pinned)
            case .startAll:
                showStartMenu(.allApps)
            case .startSearch(let text):
                showStartMenu(.search(text))
            case .switcher:
                switcher?.showForCapture()
            case .tray(let kind):
                DispatchQueue.main.async {
                    TrayFlyouts.shared.showForCapture(kind)
                }
            case .files(let path):
                let folder = path.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
                ExplorerWindow.open(at: folder ?? FileManager.default.homeDirectoryForCurrentUser)
            }
        }
    }

    private func toggleStartMenu() {
        guard let chrome else { return }
        startMenu?.toggle(origin: chrome.startMenuOrigin(menuSize:))
    }

    private func showStartMenu(_ opening: StartMenuOpening) {
        guard let chrome else { return }
        startMenu?.staysOpenForCapture = true
        startMenu?.present(origin: chrome.startMenuOrigin(menuSize:), opening: opening)
    }

    private func refreshBadges() {
        dockBadges.load { [weak self] badges in
            guard let self, badges != self.badges else { return }
            self.badges = badges
            self.refreshTaskbar()
        }
    }

    private func refreshTaskbar() {
        let apps = tracker.taskbarApps
        let entries = apps.map(Self.entry(for:))
        guard Accessibility.isTrusted else {
            chrome?.update(snapshot: TaskbarSnapshot(items: apps.map(Self.item(for:)), apps: entries, badges: badges))
            return
        }
        windowEvents.watch(apps: appsWithWindows)
        catalog.load(apps: appsWithWindows) { [weak self] windows in
            guard let self else { return }
            self.switcher?.windowsDidRefresh(windows)
            let windowless = self.refreshBackgroundApps(apps: apps, windows: windows)
            self.chrome?.update(snapshot: TaskbarSnapshot(
                items: windows.map(Self.item(for:)), apps: entries, badges: self.badges, windowless: windowless
            ))
        }
    }

    private func refreshBackgroundApps(apps: [NSRunningApplication], windows: [ShellWindow]) -> Set<String> {
        let windowCounts = Dictionary(grouping: windows, by: { $0.app.processIdentifier }).mapValues(\.count)
        let readable = catalog.readablePIDs
        let candidates = apps.map {
            BackgroundApps.Candidate(
                id: Self.appID(of: $0),
                pid: $0.processIdentifier,
                windowCount: windowCounts[$0.processIdentifier] ?? 0,
                windowsReadable: readable.contains($0.processIdentifier)
            )
        }
        let windowless = backgroundApps.settledWindowless(candidates, now: ProcessInfo.processInfo.systemUptime)
        let excluded = Set(Self.neverInTray + [Bundle.main.bundleIdentifier].compactMap { $0 })
        let ids = BackgroundApps.trayIDs(windowless: windowless, pinned: TaskbarPinStore.loadPins(), excluded: excluded)
        let byID = Dictionary(apps.map { (Self.appID(of: $0), $0) }, uniquingKeysWith: { first, _ in first })
        TrayAppsStore.shared.update(ids.compactMap { id in
            byID[id].map { TrayApp(running: $0, id: id, badge: badges[id]) }
        })
        return Set(windowless)
    }

    private static func appID(of app: NSRunningApplication) -> String {
        TaskbarAppID.make(bundleIdentifier: app.bundleIdentifier, pid: app.processIdentifier)
    }

    private static func reveal(_ app: NSRunningApplication) {
        app.unhide()
        app.activate()
    }

    private static func entry(for app: NSRunningApplication) -> TaskbarAppEntry {
        TaskbarAppEntry(
            id: appID(of: app),
            name: app.localizedName ?? "",
            icon: HoboIcon.image(for: app),
            isActive: app.isActive,
            activate: {
                if app.isActive {
                    app.hide()
                } else {
                    reveal(app)
                }
            },
            quit: { app.terminate() }
        )
    }

    private static func item(for app: NSRunningApplication) -> TaskbarItem {
        var item = TaskbarItem(icon: HoboIcon.image(for: app), title: app.localizedName ?? "", isActive: app.isActive) {
            if app.isActive {
                app.hide()
            } else {
                reveal(app)
            }
        }
        item.quit = { app.terminate() }
        item.appName = app.localizedName
        item.appID = appID(of: app)
        item.reveal = { reveal(app) }
        return item
    }

    private static func item(for window: ShellWindow) -> TaskbarItem {
        var item = TaskbarItem(icon: HoboIcon.image(for: window.app), title: window.title, isActive: window.isFocused) {
            if window.isFocused {
                WindowCatalog.minimize(window)
            } else {
                WindowCatalog.focus(window)
            }
        }
        let request = PreviewRequest(
            windowID: window.id,
            pid: window.app.processIdentifier,
            title: window.title,
            frame: window.frame,
            isMinimized: window.isMinimized
        )
        item.preview = { limit, completion in
            WindowPreview.capture(request, limit: limit, completion: completion)
        }
        item.close = { WindowCatalog.close(window) }
        item.quit = { window.app.terminate() }
        item.appName = window.app.localizedName
        item.appID = appID(of: window.app)
        item.reveal = { WindowCatalog.focus(window) }
        return item
    }

    private func registerHotKeys() {
        let snapModifiers = controlKey | optionKey
        let snapKeys: [(Int, SnapRegion)] = [
            (kVK_LeftArrow, .leftHalf),
            (kVK_RightArrow, .rightHalf),
            (kVK_UpArrow, .maximize),
        ]
        for (keyCode, region) in snapKeys {
            HotKeyCenter.shared.register(keyCode: keyCode, modifiers: snapModifiers) { [weak self] in
                self?.snapLastActiveWindow(to: region)
            }
        }
        HotKeyCenter.shared.register(keyCode: kVK_Tab, modifiers: optionKey) { [weak self] in
            self?.switcher?.openFromHotKey()
        }
        HotKeyCenter.shared.register(keyCode: kVK_Space, modifiers: optionKey) { [weak self] in
            self?.toggleStartMenu()
        }
    }

    private func snapLastActiveWindow(to region: SnapRegion) {
        guard Accessibility.isTrusted else {
            Self.snapLog.notice("snap skipped: Accessibility access is off")
            Accessibility.requestTrust()
            return
        }
        guard let app = tracker.lastActiveApp ?? NSWorkspace.shared.frontmostApplication, let screen = NSScreen.main else {
            Self.snapLog.notice("snap skipped: no app has been active yet")
            return
        }
        let reserved = ShellLayout(variant: variant, screen: screen, dockReservation: reservation(on: screen)).reserved
        let outcome = WindowSnapper.snapFrontWindow(of: app, to: region, on: screen, reserved: reserved)
        let appName = app.localizedName ?? "unknown app"
        Self.snapLog.notice("snap region \(region.rawValue) on \(appName, privacy: .public): \(outcome.description, privacy: .public)")
    }

    private func terminateCleanlyOnSignals() {
        for signalNumber in [SIGINT, SIGTERM] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler {
                NSApp.terminate(nil)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    @objc private func screensChanged() {
        buildShell()
    }

    @objc private func dockWantedChanged() {
        if SystemChrome.isWanted {
            engageDock()
            return
        }
        SystemChrome.restore()
        dockReservation = .off
        buildShell()
    }
}
