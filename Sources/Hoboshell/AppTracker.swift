import AppKit

final class AppTracker {
    var onChange: (() -> Void)?
    private(set) var lastActiveApp: NSRunningApplication?
    private var observers: [NSObjectProtocol] = []

    var taskbarApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular && !$0.isTerminated }
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
        if note.name == NSWorkspace.didActivateApplicationNotification,
           let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            lastActiveApp = app
        }
        onChange?()
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
    }
}
