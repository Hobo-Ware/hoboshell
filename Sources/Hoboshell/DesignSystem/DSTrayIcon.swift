import AppKit

final class DSTrayIcon: DSControl {
    private let height: DSControlHeight

    init(icon: NSImage?, tip: String, badge: String? = nil, height: DSControlHeight = .compact) {
        self.height = height
        super.init(frame: .zero)
        let iconView = DSIconView(side: DSIconSize.inline, image: icon)
        iconView.contentTintColor = nil
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        if let badge {
            let mark = DSBadge(badge, tone: .danger, size: .compact)
            addSubview(mark)
            NSLayoutConstraint.activate([
                mark.topAnchor.constraint(equalTo: topAnchor, constant: -DSSpacing.xxs),
                mark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: DSSpacing.xxs),
            ])
        }
        toolTip = tip
        setAccessibilityRole(.button)
        setAccessibilityLabel(badge.map { "\(tip), \($0) unread" } ?? tip)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: height.value, height: height.value)
    }
}
