import AppKit

final class TrayAppsFlyoutView: NSView {
    private let context: TrayFlyoutContext
    private var observers: [NSObjectProtocol] = []
    private let rowsStack = NSStackView()
    private lazy var rows = KeyedStack<DSListRow>(stack: rowsStack)

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = DSSpacing.xxs
        let outer = TrayFlyoutStack.make([DSSectionHeader("Running in the background"), rowsStack])
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)
        NSLayoutConstraint.activate([
            outer.leadingAnchor.constraint(equalTo: leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor),
            outer.topAnchor.constraint(equalTo: topAnchor),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        reload()
        let reload: (Notification) -> Void = { [weak self] _ in
            self?.reload()
            self?.context.refit()
        }
        observers = [
            NotificationCenter.default.addObserver(forName: TrayAppsStore.didChange, object: nil, queue: .main, using: reload),
            NotificationCenter.default.addObserver(forName: AppIcons.didLoad, object: nil, queue: .main, using: reload),
        ]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func reload() {
        let apps = TrayAppsStore.shared.flyoutApps
        let byID = Dictionary(apps.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        rows.apply(
            keys: apps.map(\.id),
            animated: false,
            make: { [weak self] _ in
                let row = DSListRow(title: "", image: nil, height: .row)
                guard let self else { return row }
                row.widthAnchor.constraint(equalTo: self.rowsStack.widthAnchor).isActive = true
                return row
            },
            update: { [weak self] row, id in
                guard let app = byID[id] else { return }
                row.update(title: app.name, image: app.resolvedIcon, detail: app.badge)
                row.onPress = { [weak self] in
                    self?.context.dismiss()
                    app.open()
                }
                row.menu = TrayAppMenu.make(for: app) { [weak self] in
                    self?.context.dismiss()
                }
            }
        )
    }
}
