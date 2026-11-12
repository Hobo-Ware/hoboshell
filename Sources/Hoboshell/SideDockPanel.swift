import AppKit

final class SideDockPanel: NSPanel {
    var onFiles: (() -> Void)?
    var onShowApps: (() -> Void)?

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []

    init(frame: NSRect, contextMenu: NSMenu, kind: DSPanelStyle.Kind = .bar) {
        super.init(contentRect: frame, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        let background = DSPanelStyle.apply(to: self, kind: kind)

        let filesButton = DSButton(image: HoboIcon.files.image(side: DSIconSize.startLogo), height: .taskbar, tip: "Files")
        filesButton.onPress = { [weak self] in
            self?.onFiles?()
        }
        let appsButton = DSButton(symbol: "square.grid.3x3.fill", tip: "Show apps", height: .taskbar)
        appsButton.onPress = { [weak self] in
            self?.onShowApps?()
        }

        itemStack.orientation = .vertical
        itemStack.spacing = DSSpacing.xs

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = DSSpacing.xs
        root.edgeInsets = NSEdgeInsets(top: DSSpacing.s, left: 0, bottom: DSSpacing.s, right: 0)
        root.addView(filesButton, in: .top)
        root.addView(itemStack, in: .top)
        root.addView(appsButton, in: .bottom)
        DSPanelStyle.pin(root, to: background)
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
            let button = DSButton(image: item.icon, height: .taskbar, tip: item.title)
            button.isSelected = item.isActive
            button.onPress = { [weak self] in
                guard let self, self.items.indices.contains(index) else { return }
                self.items[index].activate()
            }
            itemStack.addArrangedSubview(button)
        }
    }
}
