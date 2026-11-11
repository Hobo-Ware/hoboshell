import AppKit
import HoboshellCore

class DSTaskbarButton: DSButton {
    var runState: DSRunMark.State {
        get { runMark.state }
        set { runMark.state = newValue }
    }

    var countText: String? {
        didSet { countBadge = replace(countBadge, with: countText, tone: .neutral, corner: .bottomTrailing) }
    }

    var notificationText: String? {
        didSet { notificationBadge = replace(notificationBadge, with: notificationText, tone: .danger, corner: .topTrailing) }
    }

    private enum Corner {
        case topTrailing
        case bottomTrailing
    }

    private let runMark = DSRunMark()
    private var countBadge: DSBadge?
    private var notificationBadge: DSBadge?

    override init(
        title: String = "",
        image: NSImage? = nil,
        views: [NSView] = [],
        height: DSControlHeight = .taskbar,
        width: CGFloat? = nil,
        alignment: Alignment = .center,
        tip: String? = nil
    ) {
        super.init(title: title, image: image, views: views, height: height, width: width, alignment: alignment, tip: tip)
        addSubview(runMark)
        let barMargin = (ShellLayout.taskbarHeight - self.height.value) / 2
        NSLayoutConstraint.activate([
            runMark.centerXAnchor.constraint(equalTo: centerXAnchor),
            runMark.bottomAnchor.constraint(equalTo: bottomAnchor, constant: DSSpacing.xxs - barMargin),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func replace(_ old: DSBadge?, with text: String?, tone: DSBadge.Tone, corner: Corner) -> DSBadge? {
        old?.removeFromSuperview()
        guard let text else { return nil }
        let badge = DSBadge(text, tone: tone, size: .compact)
        addSubview(badge)
        let vertical = corner == .topTrailing
            ? badge.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.xxs)
            : badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.xs)
        NSLayoutConstraint.activate([
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xxs),
            vertical,
        ])
        return badge
    }
}
