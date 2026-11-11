import AppKit
import HoboshellCore

enum TaskbarMenu {
    static func make(for model: TaskbarButtonModel, onTogglePin: @escaping () -> Void) -> NSMenu {
        let isPinned = model.slot.isPinned
        let pinItem = DSMenuItem(
            isPinned ? "Unpin from taskbar" : "Pin to taskbar",
            isEnabled: isPinned || TaskbarAppID.isPinnable(model.appID),
            handler: onTogglePin
        )
        guard model.slot.isRunning else {
            let open = DSMenuItem("Open", isEnabled: model.launch != nil) { model.launch?() }
            return DSMenu.make([open, pinItem])
        }
        let closers = model.items.compactMap(\.close)
        let close = model.isGroup
            ? DSMenuItem("Close all windows") { closers.forEach { $0() } }
            : DSMenuItem("Close window", isEnabled: !closers.isEmpty) { closers.forEach { $0() } }
        let quit = DSMenuItem("Quit \(model.name)", isEnabled: model.quit != nil) { model.quit?() }
        return DSMenu.make([close, quit, DSMenu.separator(), pinItem])
    }
}
