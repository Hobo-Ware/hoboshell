import AppKit
import HoboshellCore

final class AppTracker {
    var onLaunch: ((NSRunningApplication) -> Void)?
    var onTerminate: ((pid_t) -> Void)?
    var onUserActivation: (() -> Void)?
    private(set) var lastActiveApp: NSRunningApplication?
    private var observers: [NSObjectProtocol] = []
    private var runningAppsObservation: NSKeyValueObservation?
    private var policyObservations: [pid_t: NSKeyValueObservation] = [:]
    private var announced: Set<pid_t> = []

    var taskbarApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular && !$0.isTerminated }
    }

    var shellApps: [NSRunningApplication] {
        taskbarApps + [.current]
    }

    func start() {
        lastActiveApp = NSWorkspace.shared.frontmostApplication
        let names: [NSNotification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification,
        ]
        let center = NSWorkspace.shared.notificationCenter
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                self?.handle(note)
            }
        }
        watchRunningApps()
    }

    private func watchRunningApps() {
        announced = Set(taskbarApps.map(\.processIdentifier))
        runningAppsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new]) { [weak self] _, change in
            let observedAt = ShellClock.now()
            let apps = change.newValue ?? []
            DispatchQueue.main.async {
                apps.forEach { self?.announceWhenRegular($0, observedAt: observedAt) }
            }
        }
    }

    private func announceWhenRegular(_ app: NSRunningApplication, observedAt: UInt64) {
        let pid = app.processIdentifier
        guard !announced.contains(pid), !app.isTerminated else { return }
        guard app.activationPolicy == .regular else {
            guard policyObservations[pid] == nil else { return }
            // Some apps start as accessory processes and turn into regular apps a moment later.
            policyObservations[pid] = app.observe(\.activationPolicy) { [weak self] app, _ in
                let changedAt = ShellClock.now()
                DispatchQueue.main.async {
                    self?.announceWhenRegular(app, observedAt: changedAt)
                }
            }
            return
        }
        policyObservations[pid] = nil
        announced.insert(pid)
        ShellStore.post(.appLaunched(ShellApp(running: app)), observedAt: observedAt)
        onLaunch?(app)
    }

    private func handle(_ note: Notification) {
        let observedAt = ShellClock.now()
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        let pid = app.processIdentifier
        switch note.name {
        case NSWorkspace.didLaunchApplicationNotification:
            announceWhenRegular(app, observedAt: observedAt)
        case NSWorkspace.didTerminateApplicationNotification:
            announced.remove(pid)
            policyObservations[pid] = nil
            ShellStore.post(.appTerminated(pid: pid), observedAt: observedAt)
            onTerminate?(pid)
        case NSWorkspace.didActivateApplicationNotification:
            ShellStore.post(.appActivated(pid: pid), observedAt: observedAt)
            if pid != ProcessInfo.processInfo.processIdentifier {
                lastActiveApp = app
                onUserActivation?()
            }
        case NSWorkspace.didHideApplicationNotification:
            ShellStore.post(.appHidden(pid: pid), observedAt: observedAt)
        case NSWorkspace.didUnhideApplicationNotification:
            ShellStore.post(.appUnhidden(pid: pid), observedAt: observedAt)
        default:
            break
        }
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
    }
}
