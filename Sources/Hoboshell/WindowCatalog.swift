import AppKit
import ApplicationServices
import HoboshellCore

struct ShellWindow {
    let app: NSRunningApplication
    let element: AXUIElement
    let title: String
    let frame: CGRect?
    let isMinimized: Bool
    let isFocused: Bool
    var id = 0
}

final class WindowCatalog {
    private static let messagingTimeout: Float = 0.25
    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.windows", qos: .userInitiated)
    private var listed: [(id: Int, window: ShellWindow)] = []
    private var nextID = 0
    private var retention = WindowRetention()
    private var destroyed: [AXUIElement] = []

    func load(apps: [NSRunningApplication], completion: @escaping ([ShellWindow]) -> Void) {
        let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
        queue.async { [weak self] in
            guard let self else { return }
            let windows = self.reconcile(apps: apps, frontmost: frontmost, now: ProcessInfo.processInfo.systemUptime)
            DispatchQueue.main.async {
                completion(windows)
            }
        }
    }

    func noteDestroyed(_ element: AXUIElement) {
        queue.async { [weak self] in
            self?.destroyed.append(element)
        }
    }

    private func reconcile(apps: [NSRunningApplication], frontmost: pid_t?, now: TimeInterval) -> [ShellWindow] {
        let destroyedElements = destroyed
        destroyed = []
        var readablePIDs = Set<pid_t>()
        var seen: [(id: Int, window: ShellWindow)] = []
        for app in apps {
            let pid = app.processIdentifier
            guard let windows = Self.windows(of: app, isFrontmost: pid == frontmost) else { continue }
            readablePIDs.insert(pid)
            for window in windows {
                let id = listed.first { CFEqual($0.window.element, window.element) }?.id ?? makeID()
                var identified = window
                identified.id = id
                seen.append((id, identified))
            }
        }
        let seenIDs = Set(seen.map(\.id))
        let missing = listed.filter { !seenIDs.contains($0.id) }
        let destroyedIDs = Set(missing.filter { entry in
            destroyedElements.contains { CFEqual($0, entry.window.element) }
        }.map(\.id))
        let kept = retention.keptIDs(
            missing: missing.map { WindowRetention.Known(id: $0.id, pid: $0.window.app.processIdentifier) },
            readablePIDs: readablePIDs,
            runningPIDs: Set(apps.filter { !$0.isTerminated }.map(\.processIdentifier)),
            destroyed: destroyedIDs,
            now: now
        )

        var result: [(id: Int, window: ShellWindow)] = []
        for app in apps {
            let pid = app.processIdentifier
            var group = seen.filter { $0.window.app.processIdentifier == pid }
            for (index, entry) in listed.enumerated() where kept.contains(entry.id) && entry.window.app.processIdentifier == pid {
                group.insert((entry.id, Self.refreshed(entry.window)), at: min(index, group.count))
            }
            result.append(contentsOf: group)
        }
        listed = result
        return result.map(\.window)
    }

    private func makeID() -> Int {
        nextID += 1
        return nextID
    }

    private static func refreshed(_ window: ShellWindow) -> ShellWindow {
        AXUIElementSetMessagingTimeout(window.element, messagingTimeout)
        return ShellWindow(
            app: window.app,
            element: window.element,
            title: window.title,
            frame: frame(of: window.element) ?? window.frame,
            isMinimized: attribute(kAXMinimizedAttribute, of: window.element) as? Bool ?? window.isMinimized,
            isFocused: false,
            id: window.id
        )
    }

    static func focus(_ window: ShellWindow) {
        _ = AXUIElementSetAttributeValue(window.element, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        _ = AXUIElementPerformAction(window.element, kAXRaiseAction as CFString)
        _ = AXUIElementSetAttributeValue(window.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        window.app.unhide()
        window.app.activate()
    }

    static func minimize(_ window: ShellWindow) {
        _ = AXUIElementSetAttributeValue(window.element, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }

    static func close(_ window: ShellWindow) {
        guard let button = attribute(kAXCloseButtonAttribute, of: window.element),
              CFGetTypeID(button) == AXUIElementGetTypeID() else { return }
        _ = AXUIElementPerformAction(button as! AXUIElement, kAXPressAction as CFString)
    }

    static func frame(of element: AXUIElement) -> CGRect? {
        guard let position = attribute(kAXPositionAttribute, of: element),
              let size = attribute(kAXSizeAttribute, of: element),
              CFGetTypeID(position) == AXValueGetTypeID(),
              CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
              AXValueGetValue(size as! AXValue, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    private static func windows(of app: NSRunningApplication, isFrontmost: Bool) -> [ShellWindow]? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        // An app that has stopped responding would otherwise hold each call for the system default of 6 seconds.
        AXUIElementSetMessagingTimeout(appElement, messagingTimeout)
        guard let elements = attribute(kAXWindowsAttribute, of: appElement) as? [AXUIElement] else { return nil }
        let focused = attribute(kAXFocusedWindowAttribute, of: appElement)
        let appName = app.localizedName ?? ""
        return elements.compactMap { element in
            guard attribute(kAXSubroleAttribute, of: element) as? String == kAXStandardWindowSubrole else { return nil }
            let title = attribute(kAXTitleAttribute, of: element) as? String ?? ""
            return ShellWindow(
                app: app,
                element: element,
                title: title.isEmpty ? appName : title,
                frame: frame(of: element),
                isMinimized: attribute(kAXMinimizedAttribute, of: element) as? Bool ?? false,
                isFocused: isFrontmost && focused.map { CFEqual($0, element) } ?? false
            )
        }
    }

    static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }
}
