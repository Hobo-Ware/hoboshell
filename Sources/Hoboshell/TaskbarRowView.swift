import AppKit
import HoboshellCore

final class TaskbarRowView: NSView {
    private static let gap = DSSpacing.s
    private static let leadingInset = DSSpacing.s
    private static let centrePriority = NSLayoutConstraint.Priority(700)
    private static let trayLimitPriority = NSLayoutConstraint.Priority(749)

    var alignment: TaskbarAlignment {
        didSet {
            guard oldValue != alignment else { return }
            applyAlignment()
        }
    }

    private var pinnedLeft: NSLayoutConstraint?
    private var centred: NSLayoutConstraint?

    init(group: NSStackView, trail: NSStackView, alignment: TaskbarAlignment) {
        self.alignment = alignment
        super.init(frame: .zero)
        group.translatesAutoresizingMaskIntoConstraints = false
        trail.translatesAutoresizingMaskIntoConstraints = false
        addSubview(group)
        addSubview(trail)

        let pinnedLeft = group.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingInset)
        let centred = group.centerXAnchor.constraint(equalTo: centerXAnchor)
        centred.priority = Self.centrePriority
        let trayLimit = group.trailingAnchor.constraint(lessThanOrEqualTo: trail.leadingAnchor, constant: -Self.gap)
        trayLimit.priority = Self.trayLimitPriority
        self.pinnedLeft = pinnedLeft
        self.centred = centred

        NSLayoutConstraint.activate([
            group.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Self.leadingInset),
            trayLimit,
            group.topAnchor.constraint(equalTo: topAnchor),
            group.bottomAnchor.constraint(equalTo: bottomAnchor),
            trail.trailingAnchor.constraint(equalTo: trailingAnchor),
            trail.topAnchor.constraint(equalTo: topAnchor),
            trail.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        applyAlignment()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func applyAlignment() {
        pinnedLeft?.isActive = alignment == .left
        centred?.isActive = alignment == .centred
    }
}
