import AppKit
import HoboshellCore

final class TaskbarPanel: NSPanel, ShellChrome {
    private static let buttonHeight: CGFloat = 40
    private static let iconSize: CGFloat = 24
    private static let startLogoHeight: CGFloat = 32
    private static let itemSpacing: CGFloat = 4
    private static let showDesktopWidth: CGFloat = 10
    private static let widthUsedByFixedControls: CGFloat = 380

    var actions = ShellActions()

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []
    private let previewCard = PreviewCardPanel()

    init(layout: ShellLayout, switchTitle: String) {
        super.init(contentRect: layout.bar, styleMask: ShellPanelStyle.styleMask, backing: .buffered, defer: false)
        buildContent(in: ShellPanelStyle.apply(to: self), switchTitle: switchTitle)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show() {
        orderFrontRegardless()
    }

    func dismiss() {
        previewCard.dismiss()
        orderOut(nil)
    }

    func reposition(to layout: ShellLayout) {
        setFrame(layout.bar, display: true)
        shownItems = []
        update(items: items)
    }

    func startMenuOrigin(menuSize: NSSize) -> NSPoint {
        NSPoint(x: frame.minX + 8, y: frame.maxY + 8)
    }

    func update(items: [TaskbarItem]) {
        self.items = items
        let described = items.map { "\($0.title)|\($0.isActive)" }
        guard described != shownItems else { return }
        shownItems = described

        let width = TaskbarLayout.buttonWidth(
            buttonCount: items.count,
            availableWidth: frame.width - Self.widthUsedByFixedControls,
            spacing: Self.itemSpacing
        )
        let showsTitle = TaskbarLayout.showsTitle(atWidth: width)
        itemStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        previewCard.dismiss()
        for (index, item) in items.enumerated() {
            let itemView = TaskbarItemView(
                icon: ShellButton.icon(item.icon, side: Self.iconSize),
                title: showsTitle ? item.title : nil,
                isActive: item.isActive,
                size: NSSize(width: width, height: Self.buttonHeight)
            ) { [weak self] in
                self?.activateItem(at: index)
            }
            itemView.menu = Self.menu(for: item)
            itemView.onHoverChange = { [weak self, weak itemView] isInside in
                guard let self, let itemView, isInside else {
                    self?.previewCard.pointerLeft()
                    return
                }
                self.previewCard.pointerEntered(
                    item,
                    anchor: self.convertToScreen(itemView.convert(itemView.bounds, to: nil)),
                    screen: self.screen?.frame ?? self.frame
                )
            }
            itemStack.addArrangedSubview(itemView)
        }
    }

    private func buildContent(in background: NSVisualEffectView, switchTitle: String) {
        let logo = HobowareLogo.image(height: Self.startLogoHeight, style: .official, ink: .forDarkBackground)
        let startButton = makeButton(title: logo == nil ? "⊞" : "", image: logo, action: #selector(startPressed))
        startButton.toolTip = "Start"

        let filesButton = makeButton(
            image: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Files"),
            action: #selector(filesPressed)
        )
        filesButton.toolTip = "Files"

        itemStack.orientation = .horizontal
        itemStack.spacing = Self.itemSpacing
        itemStack.setHuggingPriority(.defaultHigh, for: .horizontal)

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        root.addView(startButton, in: .leading)
        root.addView(filesButton, in: .leading)
        root.addView(itemStack, in: .leading)

        root.addView(SystemTrayView(clockOnOneLine: false), in: .trailing)

        let showDesktopButton = makeButton(width: Self.showDesktopWidth, action: #selector(showDesktopPressed))
        showDesktopButton.toolTip = "Show desktop"
        showDesktopButton.restingBackground = NSColor.white.withAlphaComponent(0.06).cgColor
        showDesktopButton.layer?.cornerRadius = 0
        root.addView(showDesktopButton, in: .trailing)

        ShellPanelStyle.pin(root, to: background)
        background.menu = ShellContextMenu(switchTitle: switchTitle) { [weak self] in
            self?.actions.onSwitchVariant?()
        }
    }

    private func makeButton(
        title: String = "",
        image: NSImage? = nil,
        width: CGFloat = TaskbarLayout.iconOnlyWidth,
        action: Selector
    ) -> HoverButton {
        ShellButton.make(
            title: title,
            image: image,
            size: NSSize(width: width, height: Self.buttonHeight),
            target: self,
            action: action
        )
    }

    @objc private func startPressed() {
        actions.onStart?()
    }

    @objc private func filesPressed() {
        actions.onFiles?()
    }

    @objc private func showDesktopPressed() {
        actions.onShowDesktop?()
    }

    private static func menu(for item: TaskbarItem) -> NSMenu? {
        let menu = NSMenu()
        if let close = item.close {
            menu.addItem(ClosureMenuItem(title: "Close window", handler: close))
        }
        if let quit = item.quit {
            menu.addItem(ClosureMenuItem(title: "Quit \(item.appName ?? "app")", handler: quit))
        }
        return menu.items.isEmpty ? nil : menu
    }

    private func activateItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        previewCard.dismiss()
        items[index].activate()
    }
}
