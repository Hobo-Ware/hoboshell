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
    var appID: String?
    var reveal: (() -> Void)?
}

struct TaskbarAppEntry {
    let id: String
    let name: String
    let icon: NSImage?
    let isActive: Bool
    let activate: () -> Void
    let quit: () -> Void
}

struct TaskbarSnapshot {
    var items: [TaskbarItem]
    var apps: [TaskbarAppEntry] = []
    var badges: [String: String] = [:]
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
    func update(snapshot: TaskbarSnapshot)
    func reposition(to layout: ShellLayout)
    func startMenuOrigin(menuSize: NSSize) -> NSPoint
}

extension ShellChrome {
    func update(snapshot: TaskbarSnapshot) {
        update(items: snapshot.items)
    }
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
