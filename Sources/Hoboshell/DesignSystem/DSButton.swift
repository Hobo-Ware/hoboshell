import AppKit

class DSButton: DSControl {
    enum Alignment {
        case center
        case leading
    }

    let height: DSControlHeight

    var fixedWidth: CGFloat? {
        didSet {
            guard oldValue != fixedWidth else { return }
            invalidateIntrinsicContentSize()
        }
    }

    var alignment: Alignment {
        didSet { applyAlignment() }
    }

    private let customViews: [NSView]
    private let content = NSStackView()
    private let iconView: DSIconView
    private let titleLabel: DSLabel
    private var centerConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?

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
        self.alignment = alignment
        super.init(frame: .zero)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        content.orientation = .horizontal
        content.spacing = height.gap
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        centerConstraint = content.centerXAnchor.constraint(equalTo: centerXAnchor)
        leadingConstraint = content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s)
        NSLayoutConstraint.activate([
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: DSSpacing.s),
            content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -DSSpacing.s),
        ])
        applyAlignment()

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

    var iconSide: CGFloat {
        get { iconView.side }
        set { iconView.side = newValue }
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

    private func applyAlignment() {
        centerConstraint?.isActive = alignment == .center
        leadingConstraint?.isActive = alignment == .leading
    }

    private func arrange() {
        let wanted: [NSView]
        if customViews.isEmpty {
            wanted = [iconView.image == nil ? nil : iconView, titleLabel.stringValue.isEmpty ? nil : titleLabel].compactMap { $0 }
        } else {
            wanted = customViews
        }
        for view in content.arrangedSubviews where !wanted.contains(view) {
            content.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for (index, view) in wanted.enumerated() {
            let arranged = content.arrangedSubviews
            if arranged.indices.contains(index), arranged[index] === view {
                continue
            }
            content.insertArrangedSubview(view, at: index)
        }
        invalidateIntrinsicContentSize()
    }
}
