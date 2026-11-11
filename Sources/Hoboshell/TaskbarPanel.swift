import AppKit
import HoboshellCore

final class TaskbarPanel: NSPanel, ShellChrome {
    private static let buttonHeight: CGFloat = 40
    private static let iconSize: CGFloat = 24
    private static let itemSpacing: CGFloat = 4
    private static let showDesktopWidth: CGFloat = 10
    private static let widthUsedByFixedControls: CGFloat = 520

    var actions = ShellActions()

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []

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
        for (index, item) in items.enumerated() {
            let button = makeButton(
                title: showsTitle ? item.title : "",
                image: ShellButton.icon(item.icon, side: Self.iconSize),
                width: width,
                fontSize: 12,
                action: #selector(itemPressed(_:))
            )
            button.tag = index
            button.toolTip = item.title
            button.layer?.backgroundColor = item.isActive ? ShellButton.activeBackground : nil
            itemStack.addArrangedSubview(button)
        }
    }

    private func buildContent(in background: NSVisualEffectView, switchTitle: String) {
        let startButton = makeButton(title: "⊞", action: #selector(startPressed))
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

        let snapButtons: [(String, SnapRegion, String)] = [
            ("◧", .leftHalf, "Snap left (Control+Option+Left)"),
            ("◨", .rightHalf, "Snap right (Control+Option+Right)"),
            ("▢", .maximize, "Maximize (Control+Option+Up)"),
        ]
        for (title, region, tip) in snapButtons {
            let button = makeButton(title: title, action: #selector(snapPressed(_:)))
            button.tag = region.rawValue
            button.toolTip = tip
            root.addView(button, in: .trailing)
        }
        root.addView(SystemTrayView(clockOnOneLine: false), in: .trailing)

        let showDesktopButton = makeButton(width: Self.showDesktopWidth, action: #selector(showDesktopPressed))
        showDesktopButton.toolTip = "Show desktop"
        showDesktopButton.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
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
        fontSize: CGFloat = 18,
        action: Selector
    ) -> NSButton {
        ShellButton.make(
            title: title,
            image: image,
            size: NSSize(width: width, height: Self.buttonHeight),
            fontSize: fontSize,
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

    @objc private func snapPressed(_ sender: NSButton) {
        guard let region = SnapRegion(rawValue: sender.tag) else { return }
        actions.onSnap?(region)
    }

    @objc private func itemPressed(_ sender: NSButton) {
        guard items.indices.contains(sender.tag) else { return }
        items[sender.tag].activate()
    }
}
