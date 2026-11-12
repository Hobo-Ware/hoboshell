import AppKit

final class ExplorerContentView: NSView {
    private static let sidebarWidth: CGFloat = 190
    private static let minimumSidebarWidth: CGFloat = 150
    private static let sidebarHoldingPriority: Float = 260

    init(toolbar: NSView, commandBar: NSView, sidebar: NSView, items: [NSView], status: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = DSColor.surface.cgColor

        let itemsContainer = NSView()
        for view in items {
            view.translatesAutoresizingMaskIntoConstraints = false
            itemsContainer.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: itemsContainer.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: itemsContainer.trailingAnchor),
                view.topAnchor.constraint(equalTo: itemsContainer.topAnchor),
                view.bottomAnchor.constraint(equalTo: itemsContainer.bottomAnchor),
            ])
        }

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(sidebar)
        split.addArrangedSubview(itemsContainer)
        split.setHoldingPriority(NSLayoutConstraint.Priority(Self.sidebarHoldingPriority), forSubviewAt: 0)
        sidebar.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumSidebarWidth).isActive = true
        sidebar.widthAnchor.constraint(lessThanOrEqualToConstant: Self.sidebarWidth * 2).isActive = true
        let preferred = sidebar.widthAnchor.constraint(equalToConstant: Self.sidebarWidth)
        preferred.priority = .defaultHigh
        preferred.isActive = true

        let statusBar = NSView()
        status.translatesAutoresizingMaskIntoConstraints = false
        statusBar.addSubview(status)
        NSLayoutConstraint.activate([
            status.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: DSSpacing.m),
            status.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -DSSpacing.m),
            status.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
        ])

        let topLine = DSDivider()
        let middleLine = DSDivider()
        let bottomLine = DSDivider()
        for view in [toolbar, commandBar, split, statusBar, topLine, middleLine, bottomLine] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            topLine.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            commandBar.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            middleLine.topAnchor.constraint(equalTo: commandBar.bottomAnchor),
            split.topAnchor.constraint(equalTo: middleLine.bottomAnchor),
            bottomLine.topAnchor.constraint(equalTo: split.bottomAnchor),
            statusBar.topAnchor.constraint(equalTo: bottomLine.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: DSControlHeight.compact.value),
            statusBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for view in [toolbar, commandBar, split, statusBar, topLine, middleLine, bottomLine] {
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
