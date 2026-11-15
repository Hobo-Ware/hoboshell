import AppKit

final class DSToggleTile: DSControl {
    enum Accessory {
        case none
        case opensSettings
        case arrow(tip: String)
    }

    static let height = DSControlHeight.taskbar.value + DSSpacing.m

    var onArrow: (() -> Void)?

    var isOn = false {
        didSet {
            guard oldValue != isOn else { return }
            isSelected = isOn
            applyColors()
        }
    }

    private let iconView = DSIconView(side: DSIconSize.toolbar)
    private let titleLabel = DSLabel("", weight: .medium)
    private let detailLabel = DSLabel("", style: .caption)
    private let opensSettingsGlyph = DSIconView(side: DSIconSize.chevron, image: DSIconSize.symbol("arrow.up.right"))
    private var arrowButton: DSButton?

    init(symbol: String, title: String, detail: String = "", accessory: Accessory = .none) {
        super.init(frame: .zero)
        cornerRadius = DSRadius.card
        restingFill = DSColor.faint
        selectedFill = DSColor.accentFill
        selectedStateFills = (DSColor.accentFillHover, DSColor.accentFillPressed)
        setAccessibilityRole(.button)

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let text = NSStackView(views: [titleLabel, detailLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 0
        text.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var views: [NSView] = [iconView, text]
        switch accessory {
        case .none:
            break
        case .opensSettings:
            views.append(opensSettingsGlyph)
        case .arrow(let tip):
            let button = DSButton(symbol: "chevron.right", tip: tip, height: .row)
            button.onPress = { [weak self] in
                self?.onArrow?()
            }
            arrowButton = button
            views.append(button)
        }
        let content = NSStackView(views: views)
        content.orientation = .horizontal
        content.alignment = .centerY
        content.spacing = DSSpacing.s
        content.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.m, bottom: 0, right: DSSpacing.s)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
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

    func update(symbol: String, title: String, detail: String) {
        iconView.image = DSIconSize.symbol(symbol, description: title)
        if titleLabel.stringValue != title {
            titleLabel.stringValue = title
        }
        if detailLabel.stringValue != detail {
            detailLabel.stringValue = detail
        }
        detailLabel.isHidden = detail.isEmpty
        setAccessibilityLabel(detail.isEmpty ? title : "\(title), \(detail)")
    }

    private func applyColors() {
        let main = isOn ? DSColor.onAccent : DSColor.text
        iconView.contentTintColor = main
        titleLabel.textColor = main
        detailLabel.textColor = main
        opensSettingsGlyph.contentTintColor = isOn ? DSColor.onAccent : DSColor.dimText
    }
}
