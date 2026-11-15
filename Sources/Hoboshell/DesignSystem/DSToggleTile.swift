import AppKit

final class DSToggleTile: DSControl {
    enum Accessory {
        case none
        case opensSettings
        case arrow(tip: String)
    }

    static let height: CGFloat = 44
    private static let arrowSectionWidth: CGFloat = 34
    private static let pressedScale: CGFloat = 0.97
    private static let opensSettingsInset = DSSpacing.xs + DSSpacing.xxs

    var onArrow: (() -> Void)?

    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            isSelected = isOn
            applyColors()
        }
    }

    override var isEnabled: Bool {
        didSet { arrowButton?.isEnabled = isEnabled }
    }

    private(set) var title = ""
    private(set) var detail = ""

    private let iconView = DSIconView(side: DSIconSize.toolbar)
    private let divider = NSView()
    private let opensSettingsGlyph = DSIconView(side: DSIconSize.chevron - 1, image: DSIconSize.symbol("arrow.up.right"))
    private let iconSection = NSLayoutGuide()
    private var arrowButton: DSButton?

    init(symbol: String, title: String, detail: String = "", accessory: Accessory = .none) {
        super.init(frame: .zero)
        cornerRadius = DSRadius.card
        restingFill = DSColor.faint
        selectedFill = DSColor.accentFill
        selectedStateFills = (DSColor.accentFillHover, DSColor.accentFillPressed)
        setAccessibilityRole(.button)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        NSLayoutConstraint.activate([iconView.centerYAnchor.constraint(equalTo: centerYAnchor)])

        switch accessory {
        case .none:
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        case .opensSettings:
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            opensSettingsGlyph.translatesAutoresizingMaskIntoConstraints = false
            addSubview(opensSettingsGlyph)
            NSLayoutConstraint.activate([
                opensSettingsGlyph.topAnchor.constraint(equalTo: topAnchor, constant: Self.opensSettingsInset),
                opensSettingsGlyph.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.opensSettingsInset),
            ])
        case .arrow(let tip):
            let button = DSButton(symbol: "chevron.right", tip: tip, height: .row)
            button.cornerRadius = DSRadius.card
            button.onPress = { [weak self] in
                self?.onArrow?()
            }
            arrowButton = button
            button.translatesAutoresizingMaskIntoConstraints = false
            divider.wantsLayer = true
            divider.translatesAutoresizingMaskIntoConstraints = false
            addSubview(divider)
            addSubview(button)
            addLayoutGuide(iconSection)
            NSLayoutConstraint.activate([
                button.trailingAnchor.constraint(equalTo: trailingAnchor),
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
                button.widthAnchor.constraint(equalToConstant: Self.arrowSectionWidth),
                iconSection.leadingAnchor.constraint(equalTo: leadingAnchor),
                iconSection.trailingAnchor.constraint(equalTo: button.leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: button.leadingAnchor),
                divider.widthAnchor.constraint(equalToConstant: 1),
                divider.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
                divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.s),
                iconView.centerXAnchor.constraint(equalTo: iconSection.centerXAnchor),
            ])
        }
        update(symbol: symbol, title: title, detail: detail)
        applyColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.height)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        scale(isPressed)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        scale(isPressed)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        scale(false)
    }

    func update(symbol: String, title: String, detail: String) {
        iconView.image = DSIconSize.symbol(symbol, description: title)
        self.title = title
        self.detail = detail
        setAccessibilityLabel(detail.isEmpty ? title : "\(title), \(detail)")
    }

    private func scale(_ pressed: Bool) {
        guard let layer else { return }
        let length = DSMotion.duration(.press)
        let pivot = CGPoint(x: layer.anchorPoint.x * layer.bounds.width, y: layer.anchorPoint.y * layer.bounds.height)
        let shift = CGPoint(x: layer.bounds.midX - pivot.x, y: layer.bounds.midY - pivot.y)
        var target = CATransform3DIdentity
        if pressed {
            target = CATransform3DTranslate(target, shift.x, shift.y, 0)
            target = CATransform3DScale(target, Self.pressedScale, Self.pressedScale, 1)
            target = CATransform3DTranslate(target, -shift.x, -shift.y, 0)
        }
        guard length > 0 else {
            layer.removeAnimation(forKey: "dsScale")
            layer.transform = target
            return
        }
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = layer.presentation()?.transform ?? layer.transform
        animation.toValue = target
        animation.duration = length
        layer.add(animation, forKey: "dsScale")
        layer.transform = target
    }

    private func applyColors() {
        iconView.contentTintColor = isOn ? DSColor.onAccent : DSColor.text
        opensSettingsGlyph.contentTintColor = isOn ? DSColor.onAccent : DSColor.dimText
        divider.layer?.backgroundColor = (isOn ? NSColor.black.withAlphaComponent(0.22) : DSColor.border).cgColor
    }
}
