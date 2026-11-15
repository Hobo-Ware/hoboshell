import AppKit

final class DSTooltipBubble: NSView {
    private static let maxTextWidth: CGFloat = 320
    private static let borderWidth: CGFloat = 1

    private let label = DSLabel("", style: .caption)

    var text: String {
        get { label.stringValue }
        set {
            guard label.stringValue != newValue else { return }
            label.stringValue = newValue
        }
    }

    init(text: String = "") {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = DSColor.raisedSurface.cgColor
        layer?.cornerRadius = DSRadius.control
        layer?.borderWidth = Self.borderWidth
        layer?.borderColor = DSColor.border.cgColor
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = Self.maxTextWidth
        self.text = text
        DSPanelStyle.pin(label, to: self, inset: DSSpacing.s)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
