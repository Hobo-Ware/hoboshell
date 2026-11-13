import AppKit

final class DSListRow: DSControl {
    private let height: DSControlHeight
    private let iconView: DSIconView
    private let label: DSLabel
    private let detailLabel = DSLabel(style: .caption, color: DSColor.dimText)

    init(title: String, image: NSImage?, detail: String? = nil, height: DSControlHeight = .regular) {
        self.height = height
        iconView = DSIconView(side: height.iconSide)
        label = DSLabel(title, style: height.textStyle)
        super.init(frame: .zero)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentHuggingPriority(.required, for: .horizontal)
        let row = NSStackView(views: [iconView, label, detailLabel])
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
        update(title: title, image: image, detail: detail)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: height.value)
    }

    func update(title: String, image: NSImage?, detail: String?) {
        if label.stringValue != title {
            label.stringValue = title
            setAccessibilityLabel(title)
        }
        if iconView.image !== image {
            iconView.image = image
        }
        iconView.isHidden = image == nil
        detailLabel.stringValue = detail ?? ""
        detailLabel.isHidden = detail == nil
    }

    func makeStatic() {
        handlesClicks = false
        tracksHover = false
    }
}
