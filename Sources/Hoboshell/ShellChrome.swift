import AppKit
import HoboshellCore

struct TaskbarItem {
    let icon: NSImage?
    let title: String
    let isActive: Bool
    let activate: () -> Void
    var preview: ((CGSize, @escaping (NSImage?) -> Void) -> Void)?
    var close: (() -> Void)?
    var quit: (() -> Void)?
    var appName: String?
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
        DSColor.desktop(for: self)
    }
}
