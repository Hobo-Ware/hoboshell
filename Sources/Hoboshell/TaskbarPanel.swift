import AppKit
import HoboshellCore

final class TaskbarPanel: NSPanel, ShellChrome {
    private static let itemSpacing = DSSpacing.xs
    private static let showDesktopWidth = DSSpacing.s
    private static let widthUsedByFixedControls: CGFloat = 380

    var actions = ShellActions()

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []
    private let previewCard = PreviewCardPanel()

    init(layout: ShellLayout, switchTitle: String) {
        super.init(contentRect: layout.bar, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        buildContent(in: DSPanelStyle.apply(to: self, kind: .bar), switchTitle: switchTitle)
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
        NSPoint(x: frame.minX + DSSpacing.s, y: frame.maxY + DSSpacing.s)
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
            let itemView = TaskbarItemView.make(
                icon: item.icon,
                title: showsTitle ? item.title : nil,
                isActive: item.isActive,
                width: width
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

    private func buildContent(in background: DSCard, switchTitle: String) {
        let logo = HobowareLogo.image(height: DSIconSize.startLogo, style: .official, ink: .forDarkBackground)
        let startButton = DSButton(title: logo == nil ? "⊞" : "", image: logo, height: .taskbar, tip: "Start")
        startButton.onPress = { [weak self] in
            self?.actions.onStart?()
        }

        let filesButton = DSButton(symbol: "folder.fill", tip: "Files", height: .taskbar)
        filesButton.onPress = { [weak self] in
            self?.actions.onFiles?()
        }

        itemStack.orientation = .horizontal
        itemStack.spacing = Self.itemSpacing
        itemStack.setHuggingPriority(.defaultHigh, for: .horizontal)

        let showDesktopButton = DSButton(height: .taskbar, width: Self.showDesktopWidth, tip: "Show desktop")
        showDesktopButton.restingFill = DSColor.faint
        showDesktopButton.cornerRadius = DSRadius.none
        showDesktopButton.onPress = { [weak self] in
            self?.actions.onShowDesktop?()
        }

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = Self.itemSpacing
        root.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: 0)
        root.addView(startButton, in: .leading)
        root.addView(filesButton, in: .leading)
        root.addView(itemStack, in: .leading)
        root.addView(SystemTrayView(clockOnOneLine: false, height: .regular), in: .trailing)
        root.addView(showDesktopButton, in: .trailing)

        DSPanelStyle.pin(root, to: background)
        background.menu = ShellContextMenu(switchTitle: switchTitle) { [weak self] in
            self?.actions.onSwitchVariant?()
        }
    }

    private static func menu(for item: TaskbarItem) -> NSMenu? {
        var items: [NSMenuItem] = []
        if let close = item.close {
            items.append(DSMenuItem("Close window", handler: close))
        }
        if let quit = item.quit {
            items.append(DSMenuItem("Quit \(item.appName ?? "app")", handler: quit))
        }
        return items.isEmpty ? nil : DSMenu.make(items)
    }

    private func activateItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        previewCard.dismiss()
        items[index].activate()
    }
}
