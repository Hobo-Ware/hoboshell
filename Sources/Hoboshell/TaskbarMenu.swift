import AppKit
import HoboshellCore

enum TaskbarMenu {
    static func make(for spec: TaskbarButtonSpec, name: String, onTogglePin: @escaping () -> Void) -> NSMenu {
        let pinItem = DSMenuItem(
            spec.isPinned ? "Unpin from taskbar" : "Pin to taskbar",
            isEnabled: spec.isPinned || TaskbarAppID.isPinnable(spec.appID),
            handler: onTogglePin
        )
        guard spec.isRunning else {
            let open = DSMenuItem("Open") { AppIcons.shared.launch(bundleID: spec.appID) }
            return DSMenu.make([open, pinItem])
        }
        let hasWindows = !spec.windowIDs.isEmpty
        let close = spec.isGroup
            ? DSMenuItem("Close all windows") { TaskbarActions.close(spec, in: ShellStore.shared.state) }
            : DSMenuItem("Close window", isEnabled: hasWindows) { TaskbarActions.close(spec, in: ShellStore.shared.state) }
        let quit = DSMenuItem("Quit \(name)", isEnabled: spec.pid != nil) { TaskbarActions.quit(spec) }
        return DSMenu.make([close, quit, DSMenu.separator(), pinItem])
    }
}
