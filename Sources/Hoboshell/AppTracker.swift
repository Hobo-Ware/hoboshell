import AppKit
import HoboshellCore

final class AppTracker {
    var onLaunch: ((NSRunningApplication) -> Void)?
    var onTerminate: ((pid_t) -> Void)?
    var onUserActivation: (() -> Void)?
    private(set) var lastActiveApp: NSRunningApplication?
    private var observers: [NSObjectProtocol] = []

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
    }

    private func handle(_ note: Notification) {
        let observedAt = ShellClock.now()
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        let pid = app.processIdentifier
        switch note.name {
        case NSWorkspace.didLaunchApplicationNotification:
            guard app.activationPolicy == .regular else { return }
            ShellStore.post(.appLaunched(ShellApp(running: app)), observedAt: observedAt)
            onLaunch?(app)
        case NSWorkspace.didTerminateApplicationNotification:
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
