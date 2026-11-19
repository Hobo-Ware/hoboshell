import AppKit
import ApplicationServices
import HoboshellCore

final class FullScreenWatcher {
    // The focused window reports full screen a moment after the space switch is announced.
    private static let recheckDelay: TimeInterval = 0.25

    var barScreen: CGRect?
    var onChange: ((Bool) -> Void)?
    private(set) var hidesBar = false
    private var observers: [NSObjectProtocol] = []

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.check()
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.recheckDelay) { [weak self] in
                    self?.check()
                }
            })
        }
    }

    func check() {
        guard let barScreen, Accessibility.isTrusted,
              let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              pid != ProcessInfo.processInfo.processIdentifier,
              let primaryHeight = NSScreen.screens.first?.frame.height else {
            apply(false)
            return
        }
        AXWorker.shared.async { [weak self] in
            let app = AXUIElementCreateApplication(pid)
            var frame: CGRect?
            var isFullScreen = false
            if let focused = WindowCatalog.attribute(kAXFocusedWindowAttribute, of: app),
               CFGetTypeID(focused) == AXUIElementGetTypeID() {
                let window = focused as! AXUIElement
                isFullScreen = WindowCatalog.attribute("AXFullScreen", of: window) as? Bool == true
                frame = WindowCatalog.frame(of: window).map { WindowNudge.flipped($0, primaryScreenHeight: primaryHeight) }
            }
            let hides = FullScreenCover.hidesBar(frontWindow: frame, isFullScreen: isFullScreen, barScreen: barScreen)
            DispatchQueue.main.async {
                self?.apply(hides)
            }
        }
    }

    private func apply(_ hides: Bool) {
        guard hides != hidesBar else { return }
        hidesBar = hides
        onChange?(hides)
    }
}
