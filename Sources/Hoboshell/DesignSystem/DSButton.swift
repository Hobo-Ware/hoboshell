import AppKit

class DSButton: DSControl {
    enum Alignment {
        case center
        case leading
    }

    let height: DSControlHeight

    private let fixedWidth: CGFloat?
    private let customViews: [NSView]
    private let content = NSStackView()
    private let iconView: DSIconView
    private let titleLabel: DSLabel

    init(
        title: String = "",
        image: NSImage? = nil,
        views: [NSView] = [],
        height: DSControlHeight = .regular,
        width: CGFloat? = nil,
        alignment: Alignment = .center,
        tip: String? = nil
    ) {
        self.height = height
        fixedWidth = width
        customViews = views
        iconView = DSIconView(side: height.iconSide, image: image)
        titleLabel = DSLabel(title, style: height.textStyle)
        super.init(frame: .zero)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        content.orientation = .horizontal
        content.spacing = height.gap
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        var constraints = [content.centerYAnchor.constraint(equalTo: centerYAnchor)]
        switch alignment {
        case .center:
            constraints.append(content.centerXAnchor.constraint(equalTo: centerXAnchor))
            constraints.append(content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: DSSpacing.s))
        case .leading:
            constraints.append(content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s))
        }
        constraints.append(content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -DSSpacing.s))
        NSLayoutConstraint.activate(constraints)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(width == nil ? .required : .defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        toolTip = tip
        setAccessibilityRole(.button)
        setAccessibilityLabel(tip ?? title)
        arrange()
    }

    convenience init(symbol: String, tip: String, height: DSControlHeight = .regular, weight: DSTextWeight? = nil) {
        self.init(image: DSIconSize.symbol(symbol, description: tip, weight: weight), height: height, tip: tip)
    }

    override var intrinsicContentSize: NSSize {
        if let fixedWidth {
            return NSSize(width: fixedWidth, height: height.value)
        }
        let isIconOnly = titleLabel.stringValue.isEmpty && customViews.isEmpty
        let width = isIconOnly ? height.value : content.fittingSize.width + DSSpacing.s * 2
        return NSSize(width: width, height: height.value)
    }

    var title: String {
        get { titleLabel.stringValue }
        set {
            titleLabel.stringValue = newValue
            arrange()
        }
    }

    var image: NSImage? {
        get { iconView.image }
        set {
            iconView.image = newValue
            arrange()
        }
    }

    private func arrange() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if customViews.isEmpty {
            if iconView.image != nil {
                content.addArrangedSubview(iconView)
            }
            if !titleLabel.stringValue.isEmpty {
                content.addArrangedSubview(titleLabel)
            }
        } else {
            customViews.forEach(content.addArrangedSubview)
        }
        invalidateIntrinsicContentSize()
    }
}
