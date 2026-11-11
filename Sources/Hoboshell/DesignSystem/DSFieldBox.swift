import AppKit

final class DSFieldBox: NSView {
    private static let borderWidth: CGFloat = 1
    private static let focusWidth: CGFloat = 2

    var radius = DSRadius.control {
        didSet { layer?.cornerRadius = radius }
    }

    var isFocused = false {
        didSet { showBorder() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = DSRadius.control
        layer?.backgroundColor = DSColor.field.cgColor
        showBorder()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func showBorder() {
        layer?.borderWidth = isFocused ? Self.focusWidth : Self.borderWidth
        layer?.borderColor = (isFocused ? DSColor.focusRing : DSColor.border).cgColor
    }
}
