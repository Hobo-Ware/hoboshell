import AppKit
import HoboshellCore

struct TaskbarItem {
    let icon: NSImage?
    let title: String
    let isActive: Bool
    let activate: () -> Void
}

final class TaskbarPanel: NSPanel {
    static let barHeight: CGFloat = 48
    private static let buttonHeight: CGFloat = 40
    private static let iconSize: CGFloat = 24
    private static let itemSpacing: CGFloat = 4
    private static let showDesktopWidth: CGFloat = 10
    private static let widthUsedByFixedControls: CGFloat = 520

    var onStart: (() -> Void)?
    var onFiles: (() -> Void)?
    var onShowDesktop: (() -> Void)?
    var onSnap: ((SnapRegion) -> Void)?

    private let itemStack = NSStackView()
    private var items: [TaskbarItem] = []
    private var shownItems: [String] = []

    init(screen: NSScreen) {
        super.init(
            contentRect: Self.frame(on: screen),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        appearance = NSAppearance(named: .darkAqua)
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovable = false
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        buildContent()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func reposition(on screen: NSScreen) {
        setFrame(Self.frame(on: screen), display: true)
        shownItems = []
        update(items: items)
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
            let icon = item.icon?.copy() as? NSImage
            icon?.size = NSSize(width: Self.iconSize, height: Self.iconSize)
            let button = makeButton(
                title: showsTitle ? item.title : "",
                image: icon,
                width: width,
                fontSize: 12,
                action: #selector(itemPressed(_:))
            )
            button.tag = index
            button.toolTip = item.title
            button.layer?.backgroundColor = item.isActive ? NSColor.white.withAlphaComponent(0.22).cgColor : nil
            itemStack.addArrangedSubview(button)
        }
    }

    private static func frame(on screen: NSScreen) -> NSRect {
        NSRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: barHeight)
    }

    private func buildContent() {
        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        contentView = background

        let startButton = makeButton(title: "⊞", action: #selector(startPressed))
        startButton.toolTip = "Start"

        let filesButton = makeButton(
            image: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Files"),
            action: #selector(filesPressed)
        )
        filesButton.toolTip = "Files"

        itemStack.orientation = .horizontal
        itemStack.spacing = Self.itemSpacing

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        root.translatesAutoresizingMaskIntoConstraints = false
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
        root.addView(SystemTrayView(), in: .trailing)

        let showDesktopButton = makeButton(width: Self.showDesktopWidth, action: #selector(showDesktopPressed))
        showDesktopButton.toolTip = "Show desktop"
        showDesktopButton.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        showDesktopButton.layer?.cornerRadius = 0
        root.addView(showDesktopButton, in: .trailing)

        background.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            root.topAnchor.constraint(equalTo: background.topAnchor),
            root.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])

        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Hoboshell", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        background.menu = menu
    }

    private func makeButton(
        title: String = "",
        image: NSImage? = nil,
        width: CGFloat = TaskbarLayout.iconOnlyWidth,
        fontSize: CGFloat = 18,
        action: Selector
    ) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        let isLabelled = image != nil && !title.isEmpty
        button.image = image
        button.imagePosition = image == nil ? .noImage : (isLabelled ? .imageLeading : .imageOnly)
        button.alignment = isLabelled ? .left : .center
        button.cell?.lineBreakMode = .byTruncatingTail
        button.isBordered = false
        button.font = .systemFont(ofSize: fontSize)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: width),
            button.heightAnchor.constraint(equalToConstant: Self.buttonHeight),
        ])
        return button
    }

    @objc private func startPressed() {
        onStart?()
    }

    @objc private func filesPressed() {
        onFiles?()
    }

    @objc private func showDesktopPressed() {
        onShowDesktop?()
    }

    @objc private func snapPressed(_ sender: NSButton) {
        guard let region = SnapRegion(rawValue: sender.tag) else { return }
        onSnap?(region)
    }

    @objc private func itemPressed(_ sender: NSButton) {
        guard items.indices.contains(sender.tag) else { return }
        items[sender.tag].activate()
    }
}
