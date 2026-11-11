import AppKit
import HoboshellCore

final class TaskbarShowDesktop {
    private static let settleDelay: TimeInterval = 1

    private var state = ShowDesktopState()
    private var ignoresActivationsUntil = Date.distantPast

    func toggle(apps: [NSRunningApplication]) {
        let visible = apps.filter { !$0.isHidden }
        switch state.toggle(visible: visible.map(\.processIdentifier)) {
        case .hide(let pids):
            settle()
            apps.filter { pids.contains($0.processIdentifier) }.forEach { $0.hide() }
        case .restore(let pids):
            settle()
            pids.compactMap(NSRunningApplication.init(processIdentifier:)).filter { !$0.isTerminated }.forEach { $0.unhide() }
        case .nothing:
            break
        }
    }

    func userActivatedApp() {
        guard Date() >= ignoresActivationsUntil else { return }
        state.userActivatedApp()
    }

    private func settle() {
        ignoresActivationsUntil = Date().addingTimeInterval(Self.settleDelay)
    }
}
