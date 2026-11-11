import AppKit
import Carbon.HIToolbox
import HoboshellCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let windowRefreshInterval: TimeInterval = 1.5
    private static let windowEventSettleDelay: TimeInterval = 0.15
    private static let savedVariantKey = "ShellVariant"
    private static let snapLog = Logger(subsystem: "dev.hoboware.hoboshell", category: "snap")

    private let tracker = AppTracker()
    private let catalog = WindowCatalog()
    private let windowEvents = WindowEventObserver()
    private let dockBadges = DockBadges()
    private let showDesktop = TaskbarShowDesktop()
    private let hidesSystemUI = ProcessInfo.processInfo.environment["HOBOSHELL_HIDE_SYSTEM_UI"] == "1"
    private var variant = ShellVariant.resolve(
        arguments: CommandLine.arguments,
        saved: UserDefaults.standard.string(forKey: AppDelegate.savedVariantKey)
    )
    private var chrome: ShellChrome?
    private var desktop: DesktopWindow?
    private var startMenu: StartMenuPanel?
    private var switcher: WindowSwitcherPanel?
    private var windowRefreshTimer: Timer?
    private var signalSources: [DispatchSourceSignal] = []
    private var badges: [String: String] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateCleanlyOnSignals()
        if hidesSystemUI || SystemChrome.isWanted {
            SystemChrome.hide()
        }
        Accessibility.requestTrust()
        MainMenu.install()

        startMenu = StartMenuPanel()
        switcher = WindowSwitcherPanel()
        buildShell()

        tracker.onChange = { [weak self] in
            self?.refreshTaskbar()
        }
        tracker.onUserActivation = { [weak self] in
            self?.showDesktop.userActivatedApp()
        }
        tracker.start()
        windowEvents.onChange = { [weak self] in
            self?.refreshTaskbar()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.windowEventSettleDelay) {
                self?.refreshTaskbar()
            }
        }
        windowRefreshTimer = Timer.scheduledTimer(withTimeInterval: Self.windowRefreshInterval, repeats: true) { [weak self] _ in
            self?.refreshBadges()
            self?.refreshTaskbar()
        }
        registerHotKeys()
        openRequestedWindows()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if SystemChrome.isHidden {
            SystemChrome.restore()
        }
    }

    private var appsWithWindows: [NSRunningApplication] {
        tracker.taskbarApps + [.current]
    }

    private func buildShell() {
        guard let screen = NSScreen.main else { return }
        chrome?.dismiss()
        desktop?.orderOut(nil)
        startMenu?.orderOut(nil)

        let layout = ShellLayout(variant: variant, screen: screen)
        let desktop = DesktopWindow(screen: screen, reserved: layout.reserved, color: variant.desktopColor)
        desktop.orderFront(nil)
        self.desktop = desktop

        let switchTitle = "Switch to \(variant.other.displayName)"
        let chrome: ShellChrome = variant == .bottomTaskbar
            ? TaskbarPanel(layout: layout, switchTitle: switchTitle)
            : TopBarDockChrome(layout: layout, switchTitle: switchTitle)
        chrome.actions = ShellActions(
            onStart: { [weak self] in
                guard let self, let chrome = self.chrome else { return }
                self.startMenu?.toggle(origin: chrome.startMenuOrigin(menuSize:))
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

    private func switchVariant() {
        variant = variant.other
        UserDefaults.standard.set(variant.rawValue, forKey: Self.savedVariantKey)
        buildShell()
    }

    private func openRequestedWindows() {
        for target in ShowTarget.parse(arguments: CommandLine.arguments) {
            switch target {
            case .start:
                guard let chrome, let startMenu else { continue }
                startMenu.toggle(origin: chrome.startMenuOrigin(menuSize:))
            case .files(let path):
                let folder = path.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
                ExplorerWindow.open(at: folder ?? FileManager.default.homeDirectoryForCurrentUser)
            }
        }
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
            self.chrome?.update(snapshot: TaskbarSnapshot(items: windows.map(Self.item(for:)), apps: entries, badges: self.badges))
        }
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
            icon: app.icon,
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
        var item = TaskbarItem(icon: app.icon, title: app.localizedName ?? "", isActive: app.isActive) {
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
        var item = TaskbarItem(icon: window.app.icon, title: window.title, isActive: window.isFocused) {
            if window.isFocused {
                WindowCatalog.minimize(window)
            } else {
                WindowCatalog.focus(window)
            }
        }
        if let frame = window.frame, !window.isMinimized {
            let pid = window.app.processIdentifier
            item.preview = { limit, completion in
                WindowPreview.capture(pid: pid, frame: frame, limit: limit, completion: completion)
            }
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
            self?.cycleWindows()
        }
    }

    private func cycleWindows() {
        guard Accessibility.isTrusted else {
            Accessibility.requestTrust()
            return
        }
        guard let switcher, let screen = NSScreen.main else { return }
        if switcher.isVisible {
            switcher.advance()
            return
        }
        catalog.load(apps: appsWithWindows) { windows in
            let focusedFirst = windows.filter(\.isFocused) + windows.filter { !$0.isFocused }
            switcher.begin(with: focusedFirst, on: screen)
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
        let reserved = ShellLayout(variant: variant, screen: screen).reserved
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
}
