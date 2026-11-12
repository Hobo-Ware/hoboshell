import AppKit

enum DSToolbarItem {
    case view(NSView)
    case flexible(NSView)
    case group([NSView])
    case divider
    case spacer
}

final class DSToolbar: NSView {
    static let height = DSControlHeight.regular.value + DSSpacing.xs * 2

    init(_ items: [DSToolbarItem]) {
        super.init(frame: .zero)
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = DSSpacing.xs
        row.alignment = .centerY
        row.distribution = .fill
        row.edgeInsets = NSEdgeInsets(top: DSSpacing.xs, left: DSSpacing.s, bottom: DSSpacing.xs, right: DSSpacing.s)
        for item in items {
            row.addArrangedSubview(Self.make(item))
        }
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: Self.height),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private static func make(_ item: DSToolbarItem) -> NSView {
        switch item {
        case .view(let view):
            return view
        case .flexible(let view):
            view.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
            return view
        case .group(let views):
            let group = NSStackView(views: views)
            group.orientation = .horizontal
            group.spacing = DSSpacing.xs
            group.alignment = .centerY
            return group
        case .divider:
            return DSDivider(.vertical)
        case .spacer:
            let spacer = NSView()
            spacer.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
            return spacer
        }
    }
}
