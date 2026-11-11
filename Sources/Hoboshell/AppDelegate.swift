import AppKit
import Carbon.HIToolbox
import HoboshellCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let windowRefreshInterval: TimeInterval = 1.5
    private static let savedVariantKey = "ShellVariant"

    private let tracker = AppTracker()
    private let catalog = WindowCatalog()
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateCleanlyOnSignals()
        if hidesSystemUI {
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
        tracker.start()
        windowRefreshTimer = Timer.scheduledTimer(withTimeInterval: Self.windowRefreshInterval, repeats: true) { [weak self] _ in
            self?.refreshTaskbar()
        }
        registerHotKeys()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if hidesSystemUI {
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
                self?.tracker.taskbarApps.forEach { $0.hide() }
            },
            onSnap: { [weak self] region in
                self?.snapLastActiveWindow(to: region)
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

    private func refreshTaskbar() {
        guard Accessibility.isTrusted else {
            chrome?.update(items: tracker.taskbarApps.map(Self.item(for:)))
            return
        }
        catalog.load(apps: appsWithWindows) { [weak self] windows in
            self?.chrome?.update(items: windows.map(Self.item(for:)))
        }
    }

    private static func item(for app: NSRunningApplication) -> TaskbarItem {
        TaskbarItem(icon: app.icon, title: app.localizedName ?? "", isActive: app.isActive) {
            if app.isActive {
                app.hide()
            } else {
                app.unhide()
                app.activate()
            }
        }
    }

    private static func item(for window: ShellWindow) -> TaskbarItem {
        TaskbarItem(icon: window.app.icon, title: window.title, isActive: window.isFocused) {
            if window.isFocused {
                WindowCatalog.minimize(window)
            } else {
                WindowCatalog.focus(window)
            }
        }
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
            Accessibility.requestTrust()
            return
        }
        guard let app = tracker.lastActiveApp, let screen = NSScreen.main else { return }
        let reserved = ShellLayout(variant: variant, screen: screen).reserved
        WindowSnapper.snapFocusedWindow(of: app, to: region, on: screen, reserved: reserved)
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
