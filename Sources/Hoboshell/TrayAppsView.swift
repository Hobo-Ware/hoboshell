import AppKit
import HoboshellCore

final class TrayAppsView: NSStackView {
    private static let flyoutKey = "flyout"

    private let height: DSControlHeight
    private var observers: [NSObjectProtocol] = []
    private lazy var icons = KeyedStack<DSControl>(stack: self)
    private var hasPresented = false

    init(height: DSControlHeight) {
        self.height = height
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = DSSpacing.xxs
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)
        reload()
        let reload: (Notification) -> Void = { [weak self] _ in
            self?.reload()
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
        let split = BackgroundApps.split(TrayAppsStore.shared.apps)
        isHidden = split.inline.isEmpty
        let apps = Dictionary(split.inline.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        icons.apply(
            keys: (split.opensFlyout ? [Self.flyoutKey] : []) + split.inline.map(\.id),
            animated: hasPresented,
            make: { [height] key in
                guard key != Self.flyoutKey else {
                    let arrow = DSButton(symbol: "chevron.up", tip: "Running in the background", height: height)
                    arrow.onPress = {
                        TrayFlyouts.shared.toggle(.apps)
                    }
                    return arrow
                }
                return DSTrayIcon(icon: nil, tip: "", height: height)
            },
            update: { view, key in
                guard let icon = view as? DSTrayIcon, let app = apps[key] else { return }
                icon.update(icon: app.resolvedIcon, tip: app.name, badge: app.badge)
                icon.onPress = {
                    app.open()
                }
                icon.menu = TrayAppMenu.make(for: app)
            }
        )
        hasPresented = true
    }
}
