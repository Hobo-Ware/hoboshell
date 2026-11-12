import ApplicationServices
import HoboshellCore

final class AppWatcher {
    typealias Post = (ShellEvent.Kind, UInt64) -> Void

    private static let appNotifications = [
        kAXWindowCreatedNotification,
        kAXFocusedWindowChangedNotification,
        kAXMainWindowChangedNotification,
        kAXApplicationActivatedNotification,
        kAXApplicationHiddenNotification,
        kAXApplicationShownNotification,
    ]
    private static let windowNotifications = [
        kAXUIElementDestroyedNotification,
        kAXTitleChangedNotification,
        kAXWindowMiniaturizedNotification,
        kAXWindowDeminiaturizedNotification,
        kAXWindowMovedNotification,
        kAXWindowResizedNotification,
    ]

    let pid: pid_t
    var onGeometryChange: ((AXUIElement) -> Void)?

    private let name: String
    private let registry: WindowRegistry
    private let post: Post
    private let element: AXUIElement
    private var observer: AXObserver?
    private var registered = Set<Int>()

    init(pid: pid_t, name: String, registry: WindowRegistry, post: @escaping Post) {
        self.pid = pid
        self.name = name
        self.registry = registry
        self.post = post
        element = AXUIElementCreateApplication(pid)
    }

    private static let callback: AXObserverCallback = { _, element, notification, context in
        guard let context else { return }
        let observedAt = ShellClock.now()
        Unmanaged<AppWatcher>.fromOpaque(context).takeUnretainedValue()
            .handle(notification as String, element: element, observedAt: observedAt)
    }

    private var pendingAppNotifications = AppWatcher.appNotifications

    @discardableResult
    func start() -> Bool {
        var created: AXObserver?
        guard AXObserverCreate(pid, Self.callback, &created) == .success, let created else { return false }
        WindowCatalog.timeout(element)
        AXWorker.shared.add(source: AXObserverGetRunLoopSource(created))
        observer = created
        registerAppNotifications()
        return true
    }

    // An app that is still starting refuses registrations, so the missing ones are tried again on every read.
    private func registerAppNotifications() {
        guard let observer, !pendingAppNotifications.isEmpty else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        pendingAppNotifications = pendingAppNotifications.filter { notification in
            let result = AXObserverAddNotification(observer, element, notification as CFString, context)
            return result != .success && result != .notificationAlreadyRegistered
        }
    }

    func stop() {
        if let observer {
            AXWorker.shared.remove(source: AXObserverGetRunLoopSource(observer))
        }
        observer = nil
        registry.forget(pid: pid)
        registered = []
    }

    func snapshot() -> [WindowState]? {
        registerAppNotifications()
        guard let elements = WindowCatalog.attribute(kAXWindowsAttribute, of: element) as? [AXUIElement] else { return nil }
        let focused = WindowCatalog.attribute(kAXFocusedWindowAttribute, of: element)
        return elements.compactMap { window in
            adopt(window).map { state(of: window, id: $0, focused: focused.map { CFEqual($0, window) } ?? false) }
        }
    }

    private func handle(_ notification: String, element window: AXUIElement, observedAt: UInt64) {
        switch notification {
        case kAXWindowCreatedNotification:
            guard let id = adopt(window) else { return }
            post(.windowCreated(state(of: window, id: id, focused: isFocused(window))), observedAt)
        case kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification:
            postFocusedWindow(observedAt)
        case kAXApplicationActivatedNotification:
            post(.appActivated(pid: pid), observedAt)
            postFocusedWindow(observedAt)
        case kAXApplicationHiddenNotification:
            post(.appHidden(pid: pid), observedAt)
        case kAXApplicationShownNotification:
            post(.appUnhidden(pid: pid), observedAt)
        case kAXUIElementDestroyedNotification:
            guard let id = registry.forget(window) else { return }
            registered.remove(id)
            post(.windowDestroyed(id: id), observedAt)
        case kAXTitleChangedNotification:
            guard let id = registry.id(of: window) else { return }
            post(.windowTitleChanged(id: id, title: title(of: window)), observedAt)
        case kAXWindowMiniaturizedNotification:
            guard let id = registry.id(of: window) else { return }
            post(.windowMinimized(id: id), observedAt)
        case kAXWindowDeminiaturizedNotification:
            guard let id = registry.id(of: window) else { return }
            post(.windowRestored(id: id), observedAt)
        case kAXWindowMovedNotification, kAXWindowResizedNotification:
            onGeometryChange?(window)
        default:
            break
        }
    }

    private func postFocusedWindow(_ observedAt: UInt64) {
        guard let focused = WindowCatalog.attribute(kAXFocusedWindowAttribute, of: element),
              CFGetTypeID(focused) == AXUIElementGetTypeID() else { return }
        let window = focused as! AXUIElement
        let isKnown = registry.id(of: window) != nil
        guard let id = adopt(window) else { return }
        if !isKnown {
            post(.windowCreated(state(of: window, id: id, focused: true)), observedAt)
        }
        post(.windowFocused(id: id), observedAt)
    }

    private func adopt(_ window: AXUIElement) -> Int? {
        guard WindowCatalog.attribute(kAXSubroleAttribute, of: window) as? String == kAXStandardWindowSubrole else { return nil }
        let resolved = registry.resolve(window, pid: pid)
        if resolved.isNew || !registered.contains(resolved.id), let observer {
            let context = Unmanaged.passUnretained(self).toOpaque()
            for notification in Self.windowNotifications {
                AXObserverAddNotification(observer, window, notification as CFString, context)
            }
            registered.insert(resolved.id)
        }
        return resolved.id
    }

    private func isFocused(_ window: AXUIElement) -> Bool {
        WindowCatalog.attribute(kAXFocusedWindowAttribute, of: element).map { CFEqual($0, window) } ?? false
    }

    private func title(of window: AXUIElement) -> String {
        let title = WindowCatalog.attribute(kAXTitleAttribute, of: window) as? String ?? ""
        return title.isEmpty ? name : title
    }

    private func state(of window: AXUIElement, id: Int, focused: Bool) -> WindowState {
        WindowState(
            id: id,
            pid: pid,
            title: title(of: window),
            isMinimized: WindowCatalog.attribute(kAXMinimizedAttribute, of: window) as? Bool ?? false,
            isFocused: focused
        )
    }
}
