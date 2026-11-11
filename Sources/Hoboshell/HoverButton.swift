import AppKit

final class HoverButton: NSButton {
    var restingBackground: CGColor? {
        didSet { showBackground() }
    }

    private var isHovered = false {
        didSet { showBackground() }
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

    private func showBackground() {
        layer?.backgroundColor = isHovered ? ShellButton.hoverBackground : restingBackground
    }
}
