import AppKit
import HoboshellCore

final class TrayAppsView: NSStackView {
    private let height: DSControlHeight
    private var observer: NSObjectProtocol?

    init(height: DSControlHeight) {
        self.height = height
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = DSSpacing.xxs
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: TrayAppsStore.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
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
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        let split = BackgroundApps.split(TrayAppsStore.shared.apps)
        isHidden = split.inline.isEmpty
        if split.opensFlyout {
            let arrow = DSButton(symbol: "chevron.up", tip: "Running in the background", height: height)
            arrow.onPress = {
                TrayFlyouts.shared.toggle(.apps)
            }
            addArrangedSubview(arrow)
        }
        for app in split.inline {
            let icon = DSTrayIcon(icon: app.icon, tip: app.name, badge: app.badge, height: height)
            icon.onPress = {
                app.open()
            }
            icon.menu = TrayAppMenu.make(for: app)
            addArrangedSubview(icon)
        }
    }
}
