import AppKit

final class SideDockPanel: NSPanel {
    private static let buttonSize = NSSize(width: 48, height: 48)
    private static let iconSize: CGFloat = 34

    var onFiles: (() -> Void)?
    var onShowApps: (() -> Void)?

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []

    init(frame: NSRect, contextMenu: NSMenu) {
        super.init(contentRect: frame, styleMask: ShellPanelStyle.styleMask, backing: .buffered, defer: false)
        let background = ShellPanelStyle.apply(to: self)

        let filesButton = makeButton(symbol: "folder.fill", tip: "Files", action: #selector(filesPressed))
        let appsButton = makeButton(symbol: "square.grid.3x3.fill", tip: "Show apps", action: #selector(showAppsPressed))

        itemStack.orientation = .vertical
        itemStack.spacing = 4

        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        root.addView(filesButton, in: .top)
        root.addView(itemStack, in: .top)
        root.addView(appsButton, in: .bottom)
        ShellPanelStyle.pin(root, to: background)
        background.menu = contextMenu
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func update(items: [TaskbarItem]) {
        self.items = items
        let described = items.map { "\($0.title)|\($0.isActive)" }
        guard described != shownItems else { return }
        shownItems = described

        itemStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.enumerated() {
            let button = ShellButton.make(
                image: ShellButton.icon(item.icon, side: Self.iconSize),
                size: Self.buttonSize,
                target: self,
                action: #selector(itemPressed(_:))
            )
            button.tag = index
            button.toolTip = item.title
            button.restingBackground = item.isActive ? ShellButton.activeBackground : nil
            itemStack.addArrangedSubview(button)
        }
    }

    private func makeButton(symbol: String, tip: String, action: Selector) -> NSButton {
        let button = ShellButton.make(
            image: NSImage(systemSymbolName: symbol, accessibilityDescription: tip),
            size: Self.buttonSize,
            target: self,
            action: action
        )
        button.toolTip = tip
        return button
    }

    @objc private func filesPressed() {
        onFiles?()
    }

    @objc private func showAppsPressed() {
        onShowApps?()
    }

    @objc private func itemPressed(_ sender: NSButton) {
        guard items.indices.contains(sender.tag) else { return }
        items[sender.tag].activate()
    }
}
