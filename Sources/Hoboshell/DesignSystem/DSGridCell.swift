import AppKit
import HoboshellCore

final class DSGridCell: DSControl, NSDraggingSource {
    static let size = NSSize(width: 96, height: 96)

    var onSelect: (() -> Void)?
    var onOpen: (() -> Void)?
    var dragItem: (() -> NSPasteboardWriting)?

    let label: NSTextField

    private let iconView = DSIconView(side: DSIconSize.grid)
    private var pressLocation: NSPoint?

    init(label: NSTextField? = nil) {
        self.label = label ?? DSLabel()
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        cornerRadius = DSRadius.card

        self.label.font = DSTextStyle.caption.font()
        self.label.textColor = DSColor.text
        self.label.alignment = .center
        self.label.maximumNumberOfLines = 2
        self.label.lineBreakMode = .byTruncatingMiddle
        self.label.cell?.wraps = true
        self.label.cell?.truncatesLastVisibleLine = true
        self.label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        addSubview(self.label)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: DSSpacing.xs),
            self.label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.xxs),
            self.label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xxs),
            self.label.heightAnchor.constraint(equalToConstant: DSTextStyle.caption.lineHeight * 2),
        ])
    }

    func show(name: String, icon: NSImage) {
        label.stringValue = name
        iconView.image = icon
        setAccessibilityLabel(name)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if label.isEditable, label.frame.contains(local) {
            return label
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        pressLocation = event.locationInWindow
        super.mouseDown(with: event)
        guard handlesClicks else { return }
        onSelect?()
        if event.clickCount == 2 {
            onOpen?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if handlesClicks {
            onSelect?()
        }
        super.rightMouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragItem, let start = pressLocation,
              hypot(event.locationInWindow.x - start.x, event.locationInWindow.y - start.y) >= TaskbarReorder.dragThreshold
        else {
            super.mouseDragged(with: event)
            return
        }
        pressLocation = nil
        cancelPress()
        let item = NSDraggingItem(pasteboardWriter: dragItem())
        item.setDraggingFrame(bounds, contents: snapshot())
        beginDraggingSession(with: [item], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .move
    }

    private func snapshot() -> NSImage? {
        guard let bitmap = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: bitmap)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmap)
        return image
    }
}
