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
    var windowID: Int?
}

struct TaskbarButtonInfo {
    let pid: Int32?
    let tip: String
    let windowCount: Int
    let view: ObjectIdentifier
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
    func update(state: ShellState, isTrusted: Bool)
    func reposition(to layout: ShellLayout)
    func startMenuOrigin(menuSize: NSSize) -> NSPoint
    var shownButtons: [TaskbarButtonInfo] { get }
}

extension ShellChrome {
    var shownButtons: [TaskbarButtonInfo] { [] }
}

extension ShellLayout {
    init(variant: ShellVariant, screen: NSScreen, dockReservation: DockReservation = .off) {
        self.init(
            variant: variant,
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            dockReservation: dockReservation
        )
    }
}

extension ShellVariant {
    var desktopColor: NSColor {
        DSColor.desktop(for: self)
    }
}
