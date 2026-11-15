import AppKit

final class DSSwitch: DSControl {
    private static let trackSize = NSSize(width: 36, height: 20)
    private static let knobInset = DSSpacing.xxs
    private static let trackBorder: CGFloat = 1.5

    var onToggle: ((Bool) -> Void)?

    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            applyLook()
        }
    }

    private let knob = NSView()
    private let ring = NSView()
    private lazy var knobLeading = knob.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.knobInset)

    init() {
        super.init(frame: .zero)
        cornerRadius = Self.trackSize.height / 2
        setAccessibilityRole(.checkBox)
        ring.wantsLayer = true
        ring.layer?.cornerRadius = cornerRadius
        ring.layer?.borderWidth = Self.trackBorder
        ring.layer?.borderColor = DSColor.dimText.cgColor
        DSPanelStyle.pin(ring, to: self)
        knob.wantsLayer = true
        knob.layer?.cornerRadius = (Self.trackSize.height - Self.knobInset * 2) / 2
        knob.translatesAutoresizingMaskIntoConstraints = false
        addSubview(knob)
        NSLayoutConstraint.activate([
            knobLeading,
            knob.centerYAnchor.constraint(equalTo: centerYAnchor),
            knob.widthAnchor.constraint(equalToConstant: Self.trackSize.height - Self.knobInset * 2),
            knob.heightAnchor.constraint(equalToConstant: Self.trackSize.height - Self.knobInset * 2),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        applyLook()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        Self.trackSize
    }

    override func activate() {
        onToggle?(!isOn)
    }

    private func applyLook() {
        let travel = Self.trackSize.width - Self.trackSize.height
        knobLeading.constant = Self.knobInset + (isOn ? travel : 0)
        knob.layer?.backgroundColor = (isOn ? DSColor.onAccent : DSColor.dimText).cgColor
        restingFill = isOn ? DSColor.accentFill : nil
        ring.isHidden = isOn
        setAccessibilityValue(isOn ? "On" : "Off")
    }
}
