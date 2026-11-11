import AppKit
import ApplicationServices

final class WindowEventObserver {
    private static let messagingTimeout: Float = 0.25
    private static let notifications = [
        kAXWindowCreatedNotification,
        kAXUIElementDestroyedNotification,
        kAXFocusedWindowChangedNotification,
        kAXMainWindowChangedNotification,
        kAXTitleChangedNotification,
        kAXWindowMiniaturizedNotification,
        kAXWindowDeminiaturizedNotification,
    ]

    var onChange: (() -> Void)?
    private var observers: [pid_t: AXObserver] = [:]

    func watch(apps: [NSRunningApplication]) {
        let running = Set(apps.map(\.processIdentifier))
        for (pid, observer) in observers where !running.contains(pid) {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            observers[pid] = nil
        }
        for pid in running where observers[pid] == nil {
            observers[pid] = makeObserver(for: pid)
        }
    }

    private func makeObserver(for pid: pid_t) -> AXObserver? {
        var created: AXObserver?
        let callback: AXObserverCallback = { _, _, _, context in
            guard let context else { return }
            Unmanaged<WindowEventObserver>.fromOpaque(context).takeUnretainedValue().onChange?()
        }
        guard AXObserverCreate(pid, callback, &created) == .success, let observer = created else { return nil }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, Self.messagingTimeout)
        let context = Unmanaged.passUnretained(self).toOpaque()
        for notification in Self.notifications {
            AXObserverAddNotification(observer, app, notification as CFString, context)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        return observer
    }
}
