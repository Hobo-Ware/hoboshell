import AppKit

enum HoverTracking {
    static func install(on view: NSView) {
        view.trackingAreas.forEach(view.removeTrackingArea)
        view.addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: view
        ))
    }
}

class HoverView: NSView {
    var restingBackground: CGColor? {
        didSet { showBackground() }
    }

    private var isHovered = false {
        didSet { showBackground() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        HoverTracking.install(on: self)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    private func showBackground() {
        layer?.backgroundColor = isHovered ? ShellButton.hoverBackground : restingBackground
    }
}
