import AppKit

final class ShellContextMenu: NSMenu, NSMenuDelegate {
    private let hideSystemUIItem = DSMenuItem("Hide the Mac Dock and desktop icons") {
        SystemChrome.setWanted(!SystemChrome.isWanted)
    }

    init(switchTitle: String, onSwitchVariant: @escaping () -> Void) {
        super.init(title: "")
        DSMenu.style(self)
        addItem(DSMenuItem(switchTitle, handler: onSwitchVariant))
        addItem(hideSystemUIItem)
        delegate = self
        addItem(DSMenu.separator())
        addItem(DSMenuItem("Quit Hoboshell") {
            NSApp.terminate(nil)
        })
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        hideSystemUIItem.state = SystemChrome.isWanted ? .on : .off
    }
}
