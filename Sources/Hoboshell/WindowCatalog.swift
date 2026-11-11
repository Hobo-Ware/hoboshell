import AppKit
import ApplicationServices

struct ShellWindow {
    let app: NSRunningApplication
    let element: AXUIElement
    let title: String
    let frame: CGRect?
    let isMinimized: Bool
    let isFocused: Bool
}

final class WindowCatalog {
    private static let messagingTimeout: Float = 0.25
    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.windows", qos: .userInitiated)

    func load(apps: [NSRunningApplication], completion: @escaping ([ShellWindow]) -> Void) {
        let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
        queue.async {
            let windows = apps.flatMap { Self.windows(of: $0, isFrontmost: $0.processIdentifier == frontmost) }
            DispatchQueue.main.async {
                completion(windows)
            }
        }
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

    private static func frame(of element: AXUIElement) -> CGRect? {
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

    private static func windows(of app: NSRunningApplication, isFrontmost: Bool) -> [ShellWindow] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        // An app that has stopped responding would otherwise hold each call for the system default of 6 seconds.
        AXUIElementSetMessagingTimeout(appElement, messagingTimeout)
        guard let elements = attribute(kAXWindowsAttribute, of: appElement) as? [AXUIElement] else { return [] }
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

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }
}
