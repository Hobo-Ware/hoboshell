import AppKit

final class TaskbarPanel: NSPanel {
    static let barHeight: CGFloat = 48
    private static let buttonSize: CGFloat = 40
    private static let iconSize: CGFloat = 28

    var onStart: (() -> Void)?
    var onSnap: ((SnapRegion) -> Void)?

    private let appStack = NSStackView()
    private let clock = NSTextField(labelWithString: "")
    private let clockFormatter = DateFormatter()
    private var clockTimer: Timer?
    private var apps: [NSRunningApplication] = []

    init(screen: NSScreen) {
        super.init(
            contentRect: Self.frame(on: screen),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovable = false
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        buildContent()
        startClock()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func reposition(on screen: NSScreen) {
        setFrame(Self.frame(on: screen), display: true)
    }

    func update(apps: [NSRunningApplication]) {
        self.apps = apps
        appStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, app) in apps.enumerated() {
            let icon = app.icon?.copy() as? NSImage ?? NSImage()
            icon.size = NSSize(width: Self.iconSize, height: Self.iconSize)
            let button = makeButton(image: icon, action: #selector(toggleApp(_:)))
            button.tag = index
            button.toolTip = app.localizedName
            button.layer?.backgroundColor = app.isActive ? NSColor.white.withAlphaComponent(0.22).cgColor : nil
            appStack.addArrangedSubview(button)
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

        appStack.orientation = .horizontal
        appStack.spacing = 4

        clock.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        clock.textColor = .white

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 12)
        root.translatesAutoresizingMaskIntoConstraints = false
        root.addView(startButton, in: .leading)
        root.addView(appStack, in: .leading)
        let snapButtons: [(String, SnapRegion, String)] = [
            ("◧", .leftHalf, "Snap left"),
            ("◨", .rightHalf, "Snap right"),
            ("▢", .maximize, "Maximize"),
        ]
        for (title, region, tip) in snapButtons {
            let button = makeButton(title: title, action: #selector(snapPressed(_:)))
            button.tag = region.rawValue
            button.toolTip = tip
            root.addView(button, in: .trailing)
        }
        root.addView(clock, in: .trailing)

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

    private func makeButton(title: String = "", image: NSImage? = nil, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.image = image
        button.imagePosition = image == nil ? .noImage : .imageOnly
        button.isBordered = false
        button.font = .systemFont(ofSize: 18)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            button.heightAnchor.constraint(equalToConstant: Self.buttonSize),
        ])
        return button
    }

    private func startClock() {
        clockFormatter.dateFormat = "HH:mm"
        updateClock()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateClock()
        }
    }

    private func updateClock() {
        clock.stringValue = clockFormatter.string(from: Date())
    }

    @objc private func startPressed() {
        onStart?()
    }

    @objc private func snapPressed(_ sender: NSButton) {
        guard let region = SnapRegion(rawValue: sender.tag) else { return }
        onSnap?(region)
    }

    @objc private func toggleApp(_ sender: NSButton) {
        guard apps.indices.contains(sender.tag) else { return }
        let app = apps[sender.tag]
        if app.isActive {
            app.hide()
        } else {
            app.unhide()
            app.activate()
        }
    }
}
