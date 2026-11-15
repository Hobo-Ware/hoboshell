import AppKit
import HoboshellCore

enum DSTrayTone {
    static let good = NSColor(srgbRed: 0.27, green: 0.77, blue: 0.44, alpha: 1)
    static let warning = NSColor(srgbRed: 0.95, green: 0.65, blue: 0.23, alpha: 1)

    static func color(_ tone: TrayTone) -> NSColor {
        switch tone {
        case .normal: return DSColor.text
        case .good: return good
        case .warning: return warning
        case .critical: return DSColor.danger
        }
    }
}

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
        let label = badge.map { "\(tip), \($0) unread" } ?? tip
        toolTip = label
        setAccessibilityLabel(label)
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
