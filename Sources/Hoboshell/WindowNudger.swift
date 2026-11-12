import AppKit
import ApplicationServices
import HoboshellCore

final class WindowNudger {
    private static let enabledKey = "NudgeWindowsAboveBar"
    private static let settleDelay: TimeInterval = 0.3

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
    }

    var barFrame: CGRect?

    private var pending: [AXUIElement] = []
    private var timer: Timer?

    func windowChanged(_ window: AXUIElement) {
        guard Self.isEnabled, barFrame != nil else { return }
        if !pending.contains(where: { CFEqual($0, window) }) {
            pending.append(window)
        }
        arm()
    }

    private func arm() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.settleDelay, repeats: false) { [weak self] _ in
            self?.settle()
        }
    }

    private func settle() {
        guard NSEvent.pressedMouseButtons == 0 else {
            arm()
            return
        }
        let windows = pending
        pending = []
        for window in windows {
            nudge(window)
        }
    }

    private func nudge(_ window: AXUIElement) {
        guard Self.isEnabled, Accessibility.isTrusted, let bar = barFrame,
              WindowCatalog.attribute(kAXSubroleAttribute, of: window) as? String == kAXStandardWindowSubrole,
              WindowCatalog.attribute(kAXMinimizedAttribute, of: window) as? Bool != true,
              WindowCatalog.attribute("AXFullScreen", of: window) as? Bool != true,
              let accessibilityFrame = WindowCatalog.frame(of: window),
              let primaryHeight = NSScreen.screens.first?.frame.height else { return }
        let frame = WindowNudge.flipped(accessibilityFrame, primaryScreenHeight: primaryHeight)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: frame.midX, y: frame.midY)) }),
              let nudged = WindowNudge.frame(for: frame, bar: bar, screen: screen.frame) else { return }
        var size = WindowNudge.flipped(nudged, primaryScreenHeight: primaryHeight).size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }
}
