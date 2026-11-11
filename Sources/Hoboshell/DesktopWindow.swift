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
            top: screen.frame.maxY - screen.visibleFrame.maxY + reserved.top + DSSpacing.m,
            left: reserved.left + DSSpacing.m,
            bottom: reserved.bottom + DSSpacing.m,
            right: reserved.right + DSSpacing.m
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
    private static let cellSize = DSGridCell.size

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

    func select(_ cell: DSGridCell?) {
        for case let other as DSGridCell in subviews {
            other.isSelected = other === cell
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
            addSubview(makeCell(for: file))
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

    private func makeCell(for file: URL) -> DSGridCell {
        let cell = DSGridCell()
        cell.show(name: file.lastPathComponent, icon: NSWorkspace.shared.icon(forFile: file.path))
        cell.toolTip = file.lastPathComponent
        cell.onSelect = { [weak self, weak cell] in
            self?.select(cell)
        }
        cell.onOpen = { [weak self] in
            self?.open(file)
        }
        cell.menu = DSMenu.make([
            DSMenuItem("Open") { [weak self] in
                self?.open(file)
            },
            DSMenu.separator(),
            DSMenuItem("Move to Trash") { [weak self] in
                self?.moveToTrash(file)
            },
        ])
        return cell
    }

    private func open(_ file: URL) {
        if FileEntry.isBrowsableFolder(file) {
            ExplorerWindow.open(at: file)
            return
        }
        NSWorkspace.shared.open(file)
    }

    private func moveToTrash(_ file: URL) {
        do {
            try FileManager.default.trashItem(at: file, resultingItemURL: nil)
            reload()
        } catch {
            DSDialog.showError(error)
        }
    }
}
