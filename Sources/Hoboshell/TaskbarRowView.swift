import AppKit
import HoboshellCore

final class TaskbarRowView: NSView {
    private static let gap = DSSpacing.s
    private static let leadingInset = DSSpacing.s

    var alignment: TaskbarAlignment {
        didSet {
            guard oldValue != alignment else { return }
            needsLayout = true
        }
    }

    private let group: NSStackView
    private let trail: NSStackView
    private var leadingConstraint: NSLayoutConstraint?
    private var observers: [NSObjectProtocol] = []

    init(group: NSStackView, trail: NSStackView, alignment: TaskbarAlignment) {
        self.group = group
        self.trail = trail
        self.alignment = alignment
        super.init(frame: .zero)
        group.translatesAutoresizingMaskIntoConstraints = false
        trail.translatesAutoresizingMaskIntoConstraints = false
        addSubview(group)
        addSubview(trail)
        let leading = group.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingInset)
        leadingConstraint = leading
        NSLayoutConstraint.activate([
            leading,
            group.topAnchor.constraint(equalTo: topAnchor),
            group.bottomAnchor.constraint(equalTo: bottomAnchor),
            trail.trailingAnchor.constraint(equalTo: trailingAnchor),
            trail.topAnchor.constraint(equalTo: topAnchor),
            trail.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for view in [group, trail] {
            view.postsFrameChangedNotifications = true
            observers.append(NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification, object: view, queue: .main
            ) { [weak self] _ in
                self?.needsLayout = true
            })
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    override func layout() {
        leadingConstraint?.constant = TaskbarPlacement.groupOriginX(
            alignment: alignment,
            barWidth: bounds.width,
            groupWidth: group.fittingSize.width,
            trailWidth: trail.fittingSize.width,
            leadingInset: Self.leadingInset,
            gap: Self.gap
        )
        super.layout()
    }
}
