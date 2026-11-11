import AppKit

final class ExplorerIconItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ExplorerIconItem")

    let nameField = ExplorerNameField(labelWithString: "")
    private lazy var tile = DSGridCell(label: nameField)

    override func loadView() {
        tile.handlesClicks = false
        view = tile
    }

    override var isSelected: Bool {
        didSet { tile.isSelected = isSelected }
    }

    func show(name: String, icon: NSImage) {
        tile.show(name: name, icon: icon)
    }
}
