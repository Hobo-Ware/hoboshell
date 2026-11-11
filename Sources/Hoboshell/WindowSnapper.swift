import AppKit
import ApplicationServices
import HoboshellCore

enum SnapOutcome: CustomStringConvertible {
    case snapped
    case noWindow
    case refused(position: AXError, size: AXError)

    var description: String {
        switch self {
        case .snapped: return "snapped"
        case .noWindow: return "no window found"
        case let .refused(position, size): return "refused (position error \(position.rawValue), size error \(size.rawValue))"
        }
    }
}

enum WindowSnapper {
    static func snapFrontWindow(
        of app: NSRunningApplication,
        to region: SnapRegion,
        on screen: NSScreen,
        reserved: ShellInsets
    ) -> SnapOutcome {
        guard let window = frontWindow(of: app) else { return .noWindow }
        var frame = SnapGeometry.accessibilityFrame(
            for: region,
            visibleFrame: screen.visibleFrame,
            screenFrame: screen.frame,
            primaryScreenHeight: NSScreen.screens.first?.frame.height ?? screen.frame.height,
            reserved: reserved
        )
        guard let position = AXValueCreate(.cgPoint, &frame.origin),
              let size = AXValueCreate(.cgSize, &frame.size) else { return .noWindow }
        // A window shrinks to fit its old screen edge when moved, so the size is set again after the move.
        _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size)
        let moved = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
        let resized = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size)
        return moved == .success && resized == .success ? .snapped : .refused(position: moved, size: resized)
    }

    private static func frontWindow(of app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        for attribute in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
            if let window = element(attribute, of: appElement) {
                return window
            }
        }
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success else { return nil }
        return (windows as? [AXUIElement])?.first
    }

    private static func element(_ attribute: String, of parent: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(parent, attribute as CFString, &value)
        guard status == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
