import AppKit
import HoboshellCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tracker = AppTracker()
    private let hidesSystemUI = ProcessInfo.processInfo.environment["HOBOSHELL_HIDE_SYSTEM_UI"] == "1"
    private var taskbar: TaskbarPanel?
    private var desktop: DesktopWindow?
    private var startMenu: StartMenuPanel?
    private var signalSources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }
        terminateCleanlyOnSignals()
        if hidesSystemUI {
            SystemChrome.hide()
        }
        Accessibility.requestTrust()

        let desktop = DesktopWindow(screen: screen, reservedBottom: TaskbarPanel.barHeight)
        desktop.orderFront(nil)
        self.desktop = desktop

        let startMenu = StartMenuPanel()
        self.startMenu = startMenu

        let taskbar = TaskbarPanel(screen: screen)
        taskbar.onStart = { [weak self] in
            guard let self, let taskbar = self.taskbar else { return }
            self.startMenu?.toggle(above: taskbar.frame)
        }
        taskbar.onFiles = {
            ExplorerWindow.open(at: FileManager.default.homeDirectoryForCurrentUser)
        }
        taskbar.onSnap = { [weak self] region in
            self?.snapLastActiveWindow(to: region)
        }
        taskbar.orderFrontRegardless()
        self.taskbar = taskbar

        tracker.onChange = { [weak self] in
            self?.refreshTaskbar()
        }
        tracker.start()
        refreshTaskbar()

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

    private func refreshTaskbar() {
        taskbar?.update(apps: tracker.taskbarApps)
    }

    private func snapLastActiveWindow(to region: SnapRegion) {
        guard Accessibility.isTrusted else {
            Accessibility.requestTrust()
            return
        }
        guard let app = tracker.lastActiveApp, let screen = NSScreen.main else { return }
        WindowSnapper.snapFocusedWindow(of: app, to: region, on: screen, reservedBottom: TaskbarPanel.barHeight)
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
        guard let screen = NSScreen.main else { return }
        taskbar?.reposition(on: screen)
        desktop?.reposition(on: screen)
    }
}
