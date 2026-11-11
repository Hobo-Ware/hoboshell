import AppKit

final class DSListRow: DSControl {
    private let height: DSControlHeight

    init(title: String, image: NSImage?, detail: String? = nil, height: DSControlHeight = .regular) {
        self.height = height
        super.init(frame: .zero)
        let label = DSLabel(title, style: height.textStyle)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        var views: [NSView] = []
        if let image {
            views.append(DSIconView(side: height.iconSide, image: image))
        }
        views.append(label)
        if let detail {
            let detailLabel = DSLabel(detail, style: .caption, color: DSColor.dimText)
            detailLabel.setContentHuggingPriority(.required, for: .horizontal)
            views.append(detailLabel)
        }
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.spacing = height.gap
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityLabel(title)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: height.value)
    }

    func makeStatic() {
        handlesClicks = false
        tracksHover = false
    }
}
