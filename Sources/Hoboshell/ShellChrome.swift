import AppKit
import HoboshellCore

struct TaskbarItem {
    let icon: NSImage?
    let title: String
    let isActive: Bool
    let activate: () -> Void
}

struct ShellActions {
    var onStart: (() -> Void)?
    var onFiles: (() -> Void)?
    var onShowDesktop: (() -> Void)?
    var onSwitchVariant: (() -> Void)?
}

protocol ShellChrome: AnyObject {
    var actions: ShellActions { get set }
    func show()
    func dismiss()
    func update(items: [TaskbarItem])
    func reposition(to layout: ShellLayout)
    func startMenuOrigin(menuSize: NSSize) -> NSPoint
}

extension ShellLayout {
    init(variant: ShellVariant, screen: NSScreen) {
        self.init(variant: variant, screenFrame: screen.frame, visibleFrame: screen.visibleFrame)
    }
}

extension ShellVariant {
    var desktopColor: NSColor {
        switch self {
        case .bottomTaskbar: return NSColor(calibratedRed: 0.0, green: 0.32, blue: 0.55, alpha: 1)
        case .topBarWithDock: return NSColor(calibratedRed: 0.27, green: 0.12, blue: 0.30, alpha: 1)
        }
    }
}
