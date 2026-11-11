import AppKit

final class ExplorerIconItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ExplorerIconItem")
    static let size = NSSize(width: 104, height: 98)

    private static let iconSide: CGFloat = 48
    private static let labelHeight: CGFloat = 32

    let nameField = ExplorerNameField(labelWithString: "")
    private let iconView = NSImageView()
    private let tile = ExplorerIconTile(frame: NSRect(origin: .zero, size: ExplorerIconItem.size))

    override func loadView() {
        iconView.frame = NSRect(
            x: (Self.size.width - Self.iconSide) / 2,
            y: Self.size.height - Self.iconSide - 6,
            width: Self.iconSide,
            height: Self.iconSide
        )
        nameField.frame = NSRect(x: 3, y: 4, width: Self.size.width - 6, height: Self.labelHeight)
        nameField.alignment = .center
        nameField.font = .systemFont(ofSize: 11)
        nameField.maximumNumberOfLines = 2
        nameField.lineBreakMode = .byTruncatingMiddle
        nameField.cell?.wraps = true
        nameField.cell?.truncatesLastVisibleLine = true
        tile.addSubview(iconView)
        tile.addSubview(nameField)
        tile.nameField = nameField
        view = tile
    }

    override var isSelected: Bool {
        didSet { tile.restingBackground = isSelected ? ExplorerTheme.selectionBackground : nil }
    }

    func show(name: String, icon: NSImage) {
        nameField.stringValue = name
        iconView.image = icon
    }
}

private final class ExplorerIconTile: HoverView {
    weak var nameField: NSTextField?

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if let nameField, nameField.isEditable, nameField.frame.contains(local) {
            return nameField
        }
        return super.hitTest(point)
    }
}
