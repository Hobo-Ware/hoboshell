import AppKit

final class DesktopWindow: NSWindow {
    init(screen: NSScreen, reservedBottom: CGFloat) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        // Finder draws its own icons at this level; one step lower and the system wallpaper would cover us.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovable = false
        hasShadow = false
        isOpaque = true
        backgroundColor = NSColor(calibratedRed: 0.0, green: 0.32, blue: 0.55, alpha: 1)
        let insets = NSEdgeInsets(
            top: screen.frame.maxY - screen.visibleFrame.maxY + 12,
            left: 12,
            bottom: reservedBottom + 12,
            right: 12
        )
        contentView = DesktopGridView(
            frame: NSRect(origin: .zero, size: screen.frame.size),
            folder: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0],
            insets: insets
        )
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func reposition(on screen: NSScreen) {
        setFrame(screen.frame, display: true)
    }
}

final class DesktopGridView: NSView {
    private static let cellSize = NSSize(width: 96, height: 92)

    private let folder: URL
    private let insets: NSEdgeInsets

    init(frame: NSRect, folder: URL, insets: NSEdgeInsets) {
        self.folder = folder
        self.insets = insets
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutIcons()
    }

    func reload() {
        subviews.forEach { $0.removeFromSuperview() }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        for file in files.sorted(by: { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }) {
            addSubview(DesktopIconView(file: file, size: Self.cellSize))
        }
        layoutIcons()
    }

    private func layoutIcons() {
        let usableHeight = bounds.height - insets.top - insets.bottom
        let rowsPerColumn = max(Int(usableHeight / Self.cellSize.height), 1)
        for (index, icon) in subviews.enumerated() {
            let column = CGFloat(index / rowsPerColumn)
            let row = CGFloat(index % rowsPerColumn)
            icon.setFrameOrigin(NSPoint(
                x: insets.left + column * Self.cellSize.width,
                y: insets.top + row * Self.cellSize.height
            ))
        }
    }
}

final class DesktopIconView: NSView {
    private let file: URL

    init(file: URL, size: NSSize) {
        self.file = file
        super.init(frame: NSRect(origin: .zero, size: size))

        let icon = NSImageView(image: NSWorkspace.shared.icon(forFile: file.path))
        icon.frame = NSRect(x: (size.width - 48) / 2, y: 4, width: 48, height: 48)

        let label = NSTextField(labelWithString: file.lastPathComponent)
        label.frame = NSRect(x: 2, y: 54, width: size.width - 4, height: 34)
        label.alignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.maximumNumberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle

        addSubview(icon)
        addSubview(label)

        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(open))
        doubleClick.numberOfClicksRequired = 2
        addGestureRecognizer(doubleClick)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    @objc private func open() {
        NSWorkspace.shared.open(file)
    }
}
