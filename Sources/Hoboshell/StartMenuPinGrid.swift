import AppKit
import HoboshellCore

final class StartMenuPinGrid: NSView {
    static let pasteboardType = NSPasteboard.PasteboardType("dev.hoboware.hoboshell.start-pin")

    private let tiles: [(id: String, cell: DSGridCell)]
    private let onMove: (String, String?) -> Void

    init(tiles: [(id: String, cell: DSGridCell)], columns: Int, onMove: @escaping (String, String?) -> Void) {
        self.tiles = tiles
        self.onMove = onMove
        super.init(frame: .zero)
        registerForDraggedTypes([Self.pasteboardType])
        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = DSSpacing.s
        rows.translatesAutoresizingMaskIntoConstraints = false
        for start in stride(from: 0, to: tiles.count, by: max(columns, 1)) {
            let row = NSStackView(views: tiles[start..<min(start + columns, tiles.count)].map(\.cell))
            row.orientation = .horizontal
            row.alignment = .top
            row.spacing = DSSpacing.s
            rows.addArrangedSubview(row)
        }
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor),
            rows.topAnchor.constraint(equalTo: topAnchor),
            rows.bottomAnchor.constraint(equalTo: bottomAnchor),
            rows.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
        ])
        for (id, cell) in tiles {
            cell.dragItem = {
                let item = NSPasteboardItem()
                item.setString(id, forType: Self.pasteboardType)
                return item
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        .move
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let id = sender.draggingPasteboard.string(forType: Self.pasteboardType) else { return false }
        let point = convert(sender.draggingLocation, from: nil)
        let others = tiles.filter { $0.id != id }.map { (id: $0.id, frame: $0.cell.convert($0.cell.bounds, to: self)) }
        onMove(id, StartPinReorder.anchor(dropPoint: point, tiles: others))
        return true
    }
}
