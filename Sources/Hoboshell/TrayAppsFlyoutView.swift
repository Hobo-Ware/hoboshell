import AppKit

final class TrayAppsFlyoutView: NSView {
    private let context: TrayFlyoutContext
    private var observer: NSObjectProtocol?
    private var stack: NSStackView?

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: TrayAppsStore.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
            self?.context.refit()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func reload() {
        stack?.removeFromSuperview()
        let rows = TrayAppsStore.shared.flyoutApps.map(makeRow)
        let next = TrayFlyoutStack.make([DSSectionHeader("Running in the background")] + rows)
        next.translatesAutoresizingMaskIntoConstraints = false
        addSubview(next)
        NSLayoutConstraint.activate([
            next.leadingAnchor.constraint(equalTo: leadingAnchor),
            next.trailingAnchor.constraint(equalTo: trailingAnchor),
            next.topAnchor.constraint(equalTo: topAnchor),
            next.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stack = next
    }

    private func makeRow(_ app: TrayApp) -> NSView {
        let row = DSListRow(title: app.name, image: app.icon, detail: app.badge, height: .row)
        row.onPress = { [weak self] in
            self?.context.dismiss()
            app.open()
        }
        row.menu = TrayAppMenu.make(for: app) { [weak self] in
            self?.context.dismiss()
        }
        return row
    }
}
