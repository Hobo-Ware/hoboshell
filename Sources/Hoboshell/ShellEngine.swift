import AppKit
import HoboshellCore

final class ShellEngine {
    private static let sweepInterval: TimeInterval = 10
    private static let trustRecheckDelay: TimeInterval = 0.5
    private static let accessibilityChanged = Notification.Name("com.apple.accessibility.api")

    let store = ShellStore.shared
    let tracker = AppTracker()
    let windowEvents = WindowEventObserver(registry: WindowCatalog.shared.registry)
    private let dockBadges = DockBadges()
    private let watchdog = MainThreadWatchdog()
    private var sweepTimer: DispatchSourceTimer?
    private var observers: [NSObjectProtocol] = []
    private(set) var isTrusted = Accessibility.isTrusted

    func runningApp(pid: pid_t) -> NSRunningApplication? {
        tracker.shellApps.first { $0.processIdentifier == pid }
    }

    func start() {
        if PerfLog.watchesMainThread {
            watchdog.start()
        }
        tracker.onLaunch = { [weak self] app in
            guard self?.isTrusted == true else { return }
            self?.windowEvents.appLaunched(pid: app.processIdentifier, name: app.localizedName ?? "")
        }
        tracker.onTerminate = { [weak self] pid in
            self?.windowEvents.appTerminated(pid: pid)
        }
        tracker.start()
        observeSystem()
        let apps = tracker.shellApps.map(ShellApp.init(running:))
        AppIcons.shared.warm(paths: apps.compactMap(\.bundlePath))
        store.apply(ShellEvent(.appsRead(apps), observedAt: ShellClock.now()))
        if isTrusted {
            syncWatchers(snapshot: .launch)
        }
        dockBadges.start()
        startSweep()
    }

    private func observeSystem() {
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            ShellStore.post(.desktopChanged)
            self?.windowEvents.desktopChanged()
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: TaskbarPinStore.didChange, object: nil, queue: .main
        ) { _ in
            ShellStore.post(.pinsChanged(TaskbarPinStore.loadPins()))
        })
        DistributedNotificationCenter.default().addObserver(
            forName: Self.accessibilityChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.recheckTrust()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.trustRecheckDelay) {
                self?.recheckTrust()
            }
        }
    }

    private func startSweep() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + Self.sweepInterval, repeating: Self.sweepInterval, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.sweep()
        }
        timer.resume()
        sweepTimer = timer
    }

    private func sweep() {
        store.apply(ShellEvent(.appsRead(tracker.shellApps.map(ShellApp.init(running:))), observedAt: 0))
        recheckTrust()
        if isTrusted {
            syncWatchers(snapshot: .sweep)
        }
    }

    private func recheckTrust() {
        let trusted = Accessibility.isTrusted
        guard trusted != isTrusted else { return }
        isTrusted = trusted
        if trusted {
            syncWatchers(snapshot: .trusted)
        } else {
            windowEvents.stopAll()
        }
        store.refresh()
    }

    private func syncWatchers(snapshot reason: ShellEvent.SnapshotReason) {
        windowEvents.sync(
            apps: tracker.shellApps.map { (pid: $0.processIdentifier, name: $0.localizedName ?? "") },
            snapshot: reason
        )
    }
}
