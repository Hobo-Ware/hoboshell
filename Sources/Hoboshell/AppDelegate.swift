import AppKit
import Carbon.HIToolbox
import HoboshellCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let neverInTray = ["com.apple.finder"]
    private static let savedVariantKey = "ShellVariant"
    private static let snapLog = Logger(subsystem: "dev.hoboware.hoboshell", category: "snap")

    private let engine = ShellEngine()
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
    private var signalSources: [DispatchSourceSignal] = []
    private var trayEntries: [BackgroundEntry] = []
    private var selfTest: RealtimeSelfTest?

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateCleanlyOnSignals()
        if !hidesSystemUI && !SystemChrome.isWanted && SystemChrome.isActive {
            SystemChrome.restore()
        }
        Accessibility.requestTrust()
        MainMenu.install()

        startMenu = StartMenuPanel()
        switcher = SwitcherController(engine: engine)
        switcher?.start()
        buildShell()

        engine.tracker.onUserActivation = { [weak self] in
            self?.showDesktop.userActivatedApp()
        }
        engine.windowEvents.onGeometryChange = { [weak self] window in
            self?.nudger.windowChanged(window)
        }
        engine.store.subscribe { [weak self] update in
            self?.render(update.state)
        }
        engine.start()
        startSelfTestIfRequested()
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

    private func startSelfTestIfRequested() {
        guard let arguments = SelfTestArguments.parse(CommandLine.arguments), let chrome else { return }
        guard variant == .bottomTaskbar else {
            print("realtime self-test could not run: start with --variant bottom-taskbar")
            exit(2)
        }
        let test = RealtimeSelfTest(engine: engine, chrome: chrome, reportPath: arguments.reportPath)
        selfTest = test
        test.start()
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
                self.showDesktop.toggle(apps: self.engine.tracker.taskbarApps)
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

    private func refreshTaskbar() {
        render(engine.store.state)
    }

    private func render(_ state: ShellState) {
        chrome?.update(state: state, isTrusted: engine.isTrusted)
        refreshTray(state)
    }

    private func refreshTray(_ state: ShellState) {
        let excluded = Set(Self.neverInTray + [Bundle.main.bundleIdentifier].compactMap { $0 })
        let entries = TrayModel.backgroundApps(state, excluded: excluded)
        guard entries != trayEntries else { return }
        trayEntries = entries
        TrayAppsStore.shared.update(entries.compactMap { entry in
            NSRunningApplication(processIdentifier: entry.pid).map { TrayApp(running: $0, id: entry.appID, badge: entry.badge) }
        })
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
        guard let app = engine.tracker.lastActiveApp ?? NSWorkspace.shared.frontmostApplication, let screen = NSScreen.main else {
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
