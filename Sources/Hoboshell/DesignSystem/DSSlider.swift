import AppKit

final class DSSlider: NSSlider {
    var onChange: ((Double) -> Void)?

    override class var cellClass: AnyClass? {
        get { DSSliderCell.self }
        set {}
    }

    init() {
        super.init(frame: .zero)
        minValue = 0
        maxValue = 1
        isContinuous = true
        target = self
        action = #selector(valueChanged)
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isEnabled: Bool {
        didSet { alphaValue = isEnabled ? 1 : DSColor.disabledAlpha }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSSliderCell.knobSide)
    }

    @objc private func valueChanged() {
        onChange?(doubleValue)
    }
}

final class DSSliderCell: NSSliderCell {
    static let knobSide: CGFloat = 16
    private static let trackHeight: CGFloat = 4
    private static let ringWidth: CGFloat = 4

    override func barRect(flipped: Bool) -> NSRect {
        let bounds = controlView?.bounds ?? .zero
        return NSRect(x: bounds.minX, y: bounds.midY - Self.trackHeight / 2, width: bounds.width, height: Self.trackHeight)
    }

    override func knobRect(flipped: Bool) -> NSRect {
        let bar = barRect(flipped: flipped)
        let span = maxValue - minValue
        let fraction = span > 0 ? CGFloat((doubleValue - minValue) / span) : 0
        let travel = bar.width - Self.knobSide
        return NSRect(x: bar.minX + travel * fraction, y: bar.midY - Self.knobSide / 2, width: Self.knobSide, height: Self.knobSide)
    }

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let radius = rect.height / 2
        DSColor.pressed.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
        var filled = rect
        filled.size.width = knobRect(flipped: flipped).midX - rect.minX
        DSColor.accent.setFill()
        NSBezierPath(roundedRect: filled, xRadius: radius, yRadius: radius).fill()
    }

    override func drawKnob(_ knobRect: NSRect) {
        DSColor.accent.setFill()
        NSBezierPath(ovalIn: knobRect).fill()
        DSColor.raisedSurface.setFill()
        NSBezierPath(ovalIn: knobRect.insetBy(dx: Self.ringWidth, dy: Self.ringWidth)).fill()
    }
}
