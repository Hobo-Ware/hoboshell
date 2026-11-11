import AppKit
import ApplicationServices

enum SnapRegion: Int {
    case leftHalf
    case rightHalf
    case maximize
}

enum WindowSnapper {
    @discardableResult
    static func snapFocusedWindow(
        of app: NSRunningApplication,
        to region: SnapRegion,
        on screen: NSScreen,
        reservedBottom: CGFloat
    ) -> Bool {
        guard let window = focusedWindow(of: app) else { return false }
        var frame = accessibilityFrame(for: region, on: screen, reservedBottom: reservedBottom)
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

    private static func accessibilityFrame(for region: SnapRegion, on screen: NSScreen, reservedBottom: CGFloat) -> CGRect {
        var usable = screen.visibleFrame
        let floor = screen.frame.minY + reservedBottom
        if usable.minY < floor {
            usable.size.height -= floor - usable.minY
            usable.origin.y = floor
        }
        switch region {
        case .leftHalf:
            usable.size.width /= 2
        case .rightHalf:
            usable.size.width /= 2
            usable.origin.x += usable.width
        case .maximize:
            break
        }
        // AppKit measures from the bottom-left of the primary screen, the Accessibility API from its top-left.
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        return CGRect(x: usable.minX, y: primaryHeight - usable.maxY, width: usable.width, height: usable.height)
    }
}
