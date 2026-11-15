import AppKit
import HoboshellCore

class DSTaskbarButton: DSButton {
    private static let plateRadius: CGFloat = 6
    private static let dipScale: CGFloat = 0.86
    private static let badgeLeading: CGFloat = 24
    private static let badgeTop: CGFloat = 3

    var facts = TaskbarButtonFacts() {
        didSet {
            guard oldValue != facts else { return }
            refresh()
        }
    }

    var runState: DSRunMark.State {
        get { runMark.state }
        set {
            var next = facts
            next.isRunning = newValue != .none
            next.isFocused = newValue == .active
            next.isBackground = newValue == .background
            facts = next
        }
    }

    var countText: String? {
        didSet {
            guard oldValue != countText else { return }
            countBadge = replace(countBadge, with: countText, tone: .neutral, corner: .bottomTrailing)
        }
    }

    var notificationText: String? {
        didSet {
            guard oldValue != notificationText else { return }
            notificationBadge = replace(notificationBadge, with: notificationText, tone: .danger, corner: .topLeading)
            facts.badge = notificationText
            refresh()
        }
    }

    override var fill: NSColor? {
        switch look.plate {
        case .none: return restingFill
        case .hover: return DSBarColor.plateHover
        case .pressed: return DSBarColor.platePressed
        case .focused: return DSBarColor.plateFocused
        case .focusedHover: return DSBarColor.plateFocusedHover
        }
    }

    private enum Corner {
        case topLeading
        case bottomTrailing
    }

    private let runMark = DSRunMark()
    private let stackedEdge = DSStackedEdge()
    private var countBadge: DSBadge?
    private var notificationBadge: DSBadge?
    private var isIconDipped = false

    private var look: TaskbarButtonAppearance {
        var current = facts
        current.isFocused = facts.isFocused || isSelected
        current.isHovered = isHovered
        current.isPressed = isPressed
        return TaskbarButtonAppearance.pick(current)
    }

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
        cornerRadius = Self.plateRadius
        iconView.wantsLayer = true
        addSubview(stackedEdge)
        addSubview(runMark)
        let barMargin = (ShellLayout.taskbarHeight - self.height.value) / 2
        NSLayoutConstraint.activate([
            runMark.centerXAnchor.constraint(equalTo: centerXAnchor),
            runMark.bottomAnchor.constraint(equalTo: bottomAnchor, constant: DSSpacing.xxs - barMargin),
            stackedEdge.leadingAnchor.constraint(equalTo: trailingAnchor),
            stackedEdge.topAnchor.constraint(equalTo: topAnchor),
            stackedEdge.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func refresh() {
        super.refresh()
        let look = look
        runMark.state = Self.markState(of: look.line)
        stackedEdge.isHidden = !look.hasStackedEdge
        notificationBadge?.isHidden = !look.showsUnread
        setIconDipped(look.dipsIcon)
        guard let layer, !isFocused else { return }
        let isLit = look.plate == .focused || look.plate == .focusedHover
        layer.borderWidth = isLit ? 1 : 0
        layer.borderColor = DSBarColor.plateEdge.cgColor
    }

    private static func markState(of line: TaskbarButtonAppearance.Line) -> DSRunMark.State {
        switch line {
        case .none: return .none
        case .dot: return .background
        case .short: return .running
        case .wide: return .active
        }
    }

    private func setIconDipped(_ dipped: Bool) {
        guard dipped != isIconDipped, let layer = iconView.layer else { return }
        isIconDipped = dipped
        let target = Self.scaled(dipped ? Self.dipScale : 1, in: layer)
        let length = window == nil ? 0 : DSMotion.duration(.press)
        if length > 0 {
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = layer.presentation()?.transform ?? layer.transform
            animation.toValue = target
            animation.duration = length
            layer.add(animation, forKey: "dsDip")
        } else {
            layer.removeAnimation(forKey: "dsDip")
        }
        layer.transform = target
    }

    private static func scaled(_ scale: CGFloat, in layer: CALayer) -> CATransform3D {
        let dx = layer.bounds.width * (0.5 - layer.anchorPoint.x)
        let dy = layer.bounds.height * (0.5 - layer.anchorPoint.y)
        let toCentre = CATransform3DMakeTranslation(dx, dy, 0)
        return CATransform3DConcat(
            CATransform3DConcat(CATransform3DMakeTranslation(-dx, -dy, 0), CATransform3DMakeScale(scale, scale, 1)),
            toCentre
        )
    }

    private func replace(_ old: DSBadge?, with text: String?, tone: DSBadge.Tone, corner: Corner) -> DSBadge? {
        old?.removeFromSuperview()
        guard let text else { return nil }
        let badge = DSBadge(text, tone: tone, size: .compact)
        addSubview(badge)
        switch corner {
        case .topLeading:
            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.badgeLeading),
                badge.topAnchor.constraint(equalTo: topAnchor, constant: Self.badgeTop),
            ])
        case .bottomTrailing:
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xxs),
                badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.xs),
            ])
        }
        return badge
    }
}

private final class DSStackedEdge: NSView {
    private static let nearWidth: CGFloat = 2
    private static let farWidth: CGFloat = 2
    private static let nearInset: CGFloat = 1
    private static let radius: CGFloat = 2

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let near = strip(DSBarColor.stackedNear)
        let far = strip(DSBarColor.stackedFar)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.nearWidth + Self.farWidth),
            near.leadingAnchor.constraint(equalTo: leadingAnchor),
            near.widthAnchor.constraint(equalToConstant: Self.nearWidth),
            near.topAnchor.constraint(equalTo: topAnchor, constant: Self.nearInset),
            near.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.nearInset),
            far.leadingAnchor.constraint(equalTo: near.trailingAnchor),
            far.widthAnchor.constraint(equalToConstant: Self.farWidth),
            far.topAnchor.constraint(equalTo: topAnchor),
            far.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func strip(_ color: NSColor) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.layer?.cornerRadius = Self.radius
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
}
