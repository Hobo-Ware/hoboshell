import AppKit

final class DSTrayIcon: DSControl {
    private let height: DSControlHeight
    private let iconView = DSIconView(side: DSIconSize.inline)
    private var badgeView: DSBadge?

    init(icon: NSImage?, tip: String, badge: String? = nil, height: DSControlHeight = .compact) {
        self.height = height
        super.init(frame: .zero)
        iconView.contentTintColor = nil
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityRole(.button)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        update(icon: icon, tip: tip, badge: badge)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: height.value, height: height.value)
    }

    func update(icon: NSImage?, tip: String, badge: String?) {
        if iconView.image !== icon {
            iconView.image = icon
        }
        toolTip = tip
        setAccessibilityLabel(badge.map { "\(tip), \($0) unread" } ?? tip)
        guard let badge else {
            badgeView?.removeFromSuperview()
            badgeView = nil
            return
        }
        if let badgeView {
            badgeView.text = badge
            return
        }
        let mark = DSBadge(badge, tone: .danger, size: .compact)
        addSubview(mark)
        NSLayoutConstraint.activate([
            mark.topAnchor.constraint(equalTo: topAnchor, constant: -DSSpacing.xxs),
            mark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: DSSpacing.xxs),
        ])
        badgeView = mark
    }
}
