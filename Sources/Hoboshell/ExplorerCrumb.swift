import AppKit

final class ExplorerCrumb: DSControl {
    private static let height = DSControlHeight.compact

    private let label: DSLabel
    private let icon: DSIconView?
    private let row: NSStackView
    private let restingColor: NSColor

    init(title: String, symbol: String? = nil, isCurrent: Bool = false) {
        let color = isCurrent ? DSColor.text : DSColor.dimText
        let label = DSLabel(title, style: .body, weight: isCurrent ? .medium : .regular, color: color)
        let icon = symbol.map {
            DSIconView(side: DSIconSize.inline, image: DSIconSize.symbol($0, description: title, weight: .medium), tint: color)
        }
        restingColor = color
        self.label = label
        self.icon = icon
        row = NSStackView(views: [icon, label].compactMap { $0 })
        super.init(frame: .zero)
        row.orientation = .horizontal
        row.spacing = DSSpacing.xs
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.xs),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xs),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        label.lineBreakMode = .byClipping
        setAccessibilityRole(.button)
        setAccessibilityLabel(title)
        onHoverChange = { [weak self] isHovered in
            self?.tone(isHovered)
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: ceil(row.fittingSize.width) + DSSpacing.xs * 2, height: Self.height.value)
    }

    private func tone(_ isHovered: Bool) {
        let color = isHovered ? DSColor.text : restingColor
        label.textColor = color
        icon?.contentTintColor = color
    }
}
