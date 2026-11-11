import AppKit

final class ExplorerContentView: NSView {
    private static let minimumSidebarWidth: CGFloat = 150
    private static let sidebarHoldingPriority: Float = 260
    private static let statusInset: CGFloat = 10

    init(toolbar: NSView, commandBar: NSView, sidebar: NSView, items: [NSView], status: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = ExplorerTheme.background.cgColor

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
        sidebar.widthAnchor.constraint(lessThanOrEqualToConstant: ExplorerTheme.sidebarWidth * 2).isActive = true
        let preferred = sidebar.widthAnchor.constraint(equalToConstant: ExplorerTheme.sidebarWidth)
        preferred.priority = .defaultHigh
        preferred.isActive = true

        let topLine = ExplorerTheme.separator()
        let middleLine = ExplorerTheme.separator()
        let bottomLine = ExplorerTheme.separator()
        for view in [toolbar, commandBar, split, status, topLine, middleLine, bottomLine] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: ExplorerTheme.toolbarHeight),
            topLine.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            commandBar.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            commandBar.heightAnchor.constraint(equalToConstant: ExplorerTheme.commandBarHeight),
            middleLine.topAnchor.constraint(equalTo: commandBar.bottomAnchor),
            split.topAnchor.constraint(equalTo: middleLine.bottomAnchor),
            bottomLine.topAnchor.constraint(equalTo: split.bottomAnchor),
            status.topAnchor.constraint(equalTo: bottomLine.bottomAnchor),
            status.heightAnchor.constraint(equalToConstant: ExplorerTheme.statusBarHeight),
            status.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for view in [toolbar, commandBar, split, topLine, middleLine, bottomLine] {
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
        status.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.statusInset).isActive = true
        status.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.statusInset).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
