import AppKit
import ApplicationServices
import HoboshellCore

enum WindowSnapper {
    @discardableResult
    static func snapFocusedWindow(
        of app: NSRunningApplication,
        to region: SnapRegion,
        on screen: NSScreen,
        reserved: ShellInsets
    ) -> Bool {
        guard let window = focusedWindow(of: app) else { return false }
        var frame = SnapGeometry.accessibilityFrame(
            for: region,
            visibleFrame: screen.visibleFrame,
            screenFrame: screen.frame,
            primaryScreenHeight: NSScreen.screens.first?.frame.height ?? screen.frame.height,
            reserved: reserved
        )
        guard let position = AXValueCreate(.cgPoint, &frame.origin),
              let size = AXValueCreate(.cgSize, &frame.size) else { return false }
        let moved = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
        let resized = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size)
        return moved == .success && resized == .success
    }

    private static func focusedWindow(of app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value)
        guard status == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
