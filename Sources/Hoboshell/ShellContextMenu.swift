import AppKit

final class ShellContextMenu: NSMenu {
    private let onSwitchVariant: () -> Void

    init(switchTitle: String, onSwitchVariant: @escaping () -> Void) {
        self.onSwitchVariant = onSwitchVariant
        super.init(title: "")
        addItem(withTitle: switchTitle, action: #selector(switchVariantPressed), keyEquivalent: "").target = self
        addItem(.separator())
        addItem(withTitle: "Quit Hoboshell", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func switchVariantPressed() {
        onSwitchVariant()
    }
}
