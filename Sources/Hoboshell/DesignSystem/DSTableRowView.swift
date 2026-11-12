import AppKit

final class DSTableRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("DSTableRowView")

    var selectionFill = DSColor.selected
    var radius = DSRadius.control
    var inset = NSSize.zero

    private let hoverSync = DSHoverSync()

    private var isHovered = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hoverSync.follow(scrollingOf: self) { [weak self] in
            self?.matchHoverToPointer()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isHovered = false
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = !isGroupRowStyle
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        guard isHovered, !isSelected else { return }
        fill(DSColor.hover)
    }

    override func drawSelection(in dirtyRect: NSRect) {
        fill(selectionFill)
    }

    func useAccentStyle() {
        selectionFill = DSColor.accentTint
        radius = DSRadius.card
        inset = NSSize(width: DSSpacing.xs, height: DSSpacing.xxs)
        needsDisplay = true
    }

    private func matchHoverToPointer() {
        let shouldHover = !isGroupRowStyle && DSHoverSync.isPointerInside(self)
        if isHovered != shouldHover {
            isHovered = shouldHover
        }
    }

    private func fill(_ color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: inset.width, dy: inset.height), xRadius: radius, yRadius: radius).fill()
    }
}
