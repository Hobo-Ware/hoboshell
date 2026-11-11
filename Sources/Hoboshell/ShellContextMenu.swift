import AppKit

final class ShellContextMenu: NSMenu, NSMenuDelegate {
    private let onSwitchVariant: () -> Void
    private let hideSystemUIItem = NSMenuItem(
        title: "Hide the Mac Dock and desktop icons",
        action: #selector(hideSystemUIPressed),
        keyEquivalent: ""
    )

    init(switchTitle: String, onSwitchVariant: @escaping () -> Void) {
        self.onSwitchVariant = onSwitchVariant
        super.init(title: "")
        addItem(withTitle: switchTitle, action: #selector(switchVariantPressed), keyEquivalent: "").target = self
        addItem(hideSystemUIItem)
        hideSystemUIItem.target = self
        delegate = self
        addItem(.separator())
        addItem(withTitle: "Quit Hoboshell", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        hideSystemUIItem.state = SystemChrome.isWanted ? .on : .off
    }

    @objc private func hideSystemUIPressed() {
        SystemChrome.setWanted(!SystemChrome.isWanted)
    }

    @objc private func switchVariantPressed() {
        onSwitchVariant()
    }
}
