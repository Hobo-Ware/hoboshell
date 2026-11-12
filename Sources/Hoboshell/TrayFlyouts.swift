import AppKit
import Carbon.HIToolbox
import HoboshellCore

final class TrayFlyouts {
    static let shared = TrayFlyouts()

    private static let appsWidth: CGFloat = 280

    var staysOpenForCapture = false

    private var anchors: [TrayItemKind: () -> NSView?] = [:]
    private var panel: TrayFlyoutPanel?
    private var monitors: [Any] = []
    private var activationObserver: NSObjectProtocol?

    func register(_ kind: TrayItemKind, anchor: @escaping () -> NSView?) {
        anchors[kind] = anchor
    }

    func toggle(_ kind: TrayItemKind) {
        if panel?.kind == kind {
            dismiss()
        } else {
            show(kind)
        }
    }

    func showForCapture(_ kind: TrayItemKind) {
        staysOpenForCapture = true
        if kind == .apps {
            TrayAppsStore.shared.showsSamples = true
        }
        show(kind)
    }

    func show(_ kind: TrayItemKind) {
        dismiss()
        let context = TrayFlyoutContext { [weak self] in self?.dismiss() }
        let (content, width) = makeContent(kind, context: context)
        let next = TrayFlyoutPanel(kind: kind, content: content, width: width) { [weak self] in
            self?.anchorFrame(for: kind)
        }
        context.panel = next
        panel = next
        next.present()
        if !staysOpenForCapture {
            startWatching()
        }
    }

    func dismiss() {
        stopWatching()
        panel?.orderOut(nil)
        panel = nil
    }

    private func makeContent(_ kind: TrayItemKind, context: TrayFlyoutContext) -> (NSView, CGFloat) {
        switch kind {
        case .apps: return (TrayAppsFlyoutView(context: context), Self.appsWidth)
        }
    }

    private func anchorFrame(for kind: TrayItemKind) -> (frame: NSRect, screen: NSRect)? {
        guard let view = anchors[kind]?(), let window = view.window else { return nil }
        window.contentView?.layoutSubtreeIfNeeded()
        let frame = window.convertToScreen(view.convert(view.bounds, to: nil))
        guard let screen = window.screen?.frame ?? NSScreen.main?.frame else { return nil }
        return (frame, screen)
    }

    private func isOnAnchor(_ event: NSEvent) -> Bool {
        guard let kind = panel?.kind, let anchor = anchors[kind]?(),
              let hit = event.window?.contentView?.superview?.hitTest(event.locationInWindow) else { return false }
        return hit.isDescendant(of: anchor)
    }

    private func startWatching() {
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let outside = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self] _ in
            self?.dismiss()
        }) {
            monitors.append(outside)
        }
        let inside = NSEvent.addLocalMonitorForEvents(matching: clicks) { [weak self] event in
            guard let self, event.window !== self.panel, !self.isOnAnchor(event) else { return event }
            self.dismiss()
            return event
        }
        let escapeLocal = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard Int(event.keyCode) == kVK_Escape else { return event }
            self?.dismiss()
            return nil
        }
        let escapeGlobal = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if Int(event.keyCode) == kVK_Escape {
                self?.dismiss()
            }
        }
        monitors.append(contentsOf: [inside, escapeLocal, escapeGlobal].compactMap { $0 })
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard app?.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
            self?.dismiss()
        }
    }

    private func stopWatching() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = nil
    }
}
