import AppKit

final class DSCard: NSVisualEffectView {
    private static let borderWidth: CGFloat = 1

    init(radius: CGFloat = DSRadius.card, isBordered: Bool = true, isTinted: Bool = true, tint: NSColor = DSColor.flyoutTint) {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = radius
        layer?.masksToBounds = true
        if isTinted {
            let tintView = NSView()
            tintView.wantsLayer = true
            tintView.layer?.backgroundColor = tint.cgColor
            DSPanelStyle.pin(tintView, to: self)
        }
        if isBordered {
            layer?.borderWidth = Self.borderWidth
            layer?.borderColor = DSColor.border.cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
