import AppKit
import HoboshellCore

final class DesktopWindow: NSWindow {
    init(screen: NSScreen, reserved: ShellInsets, color: NSColor) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        // Finder's own desktop sits at desktopIconWindow and takes every click there, so we sit one step above it.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovable = false
        hasShadow = false
        isReleasedWhenClosed = false
        isOpaque = true
        backgroundColor = color
        let insets = NSEdgeInsets(
            top: screen.frame.maxY - screen.visibleFrame.maxY + reserved.top + 12,
            left: reserved.left + 12,
            bottom: reserved.bottom + 12,
            right: reserved.right + 12
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

    override func mouseDown(with event: NSEvent) {
        select(nil)
    }

    func select(_ icon: DesktopIconView?) {
        for case let other as DesktopIconView in subviews {
            other.isSelected = other === icon
        }
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

final class DesktopIconView: HoverView {
    private static let selectedBackground = NSColor.white.withAlphaComponent(0.28).cgColor

    private let file: URL

    var isSelected = false {
        didSet { restingBackground = isSelected ? Self.selectedBackground : nil }
    }

    init(file: URL, size: NSSize) {
        self.file = file
        super.init(frame: NSRect(origin: .zero, size: size))
        toolTip = file.lastPathComponent

        let icon = NSImageView(image: NSWorkspace.shared.icon(forFile: file.path))
        icon.frame = NSRect(x: (size.width - 48) / 2, y: 4, width: 48, height: 48)

        let label = NSTextField(wrappingLabelWithString: file.lastPathComponent)
        label.frame = NSRect(x: 2, y: 54, width: size.width - 4, height: 34)
        label.alignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.isSelectable = false
        label.maximumNumberOfLines = 2
        label.cell?.truncatesLastVisibleLine = true

        addSubview(icon)
        addSubview(label)

        let menu = NSMenu()
        menu.addItem(withTitle: "Open", action: #selector(open), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Move to Trash", action: #selector(moveToTrash), keyEquivalent: "").target = self
        self.menu = menu
    }

    override var isFlipped: Bool { true }

    override func mouseDown(with event: NSEvent) {
        (superview as? DesktopGridView)?.select(self)
        if event.clickCount == 2 {
            open()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        (superview as? DesktopGridView)?.select(self)
        super.rightMouseDown(with: event)
    }

    @objc private func open() {
        if FileEntry.isBrowsableFolder(file) {
            ExplorerWindow.open(at: file)
            return
        }
        NSWorkspace.shared.open(file)
    }

    @objc private func moveToTrash() {
        do {
            try FileManager.default.trashItem(at: file, resultingItemURL: nil)
            (superview as? DesktopGridView)?.reload()
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
