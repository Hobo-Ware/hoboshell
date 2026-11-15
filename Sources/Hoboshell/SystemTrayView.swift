import AppKit
import HoboshellCore

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5

    private let clock = DSLabel(style: .caption, monospacedDigits: true)
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let longDateFormatter = DateFormatter()
    private let clockOnOneLine: Bool
    private var refreshTimer: Timer?
    private var clockItem: DSButton?
    private let appsView: TrayAppsView
    private let drivesItem: TrayDrivesItem
    private let cluster: TrayClusterButton

    init(clockOnOneLine: Bool, height: DSControlHeight) {
        self.clockOnOneLine = clockOnOneLine
        appsView = TrayAppsView(height: height)
        drivesItem = TrayDrivesItem(height: height)
        cluster = TrayClusterButton(height: height)
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = DSSpacing.xs
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)
        timeFormatter.locale = .autoupdatingCurrent
        timeFormatter.timeStyle = .short
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.dateStyle = .short
        longDateFormatter.locale = .autoupdatingCurrent
        longDateFormatter.dateStyle = .full

        clock.alignment = .right
        clock.maximumNumberOfLines = clockOnOneLine ? 1 : 2

        let clockItem = DSButton(views: [clock], height: height, tip: "Calendar")
        clockItem.onPress = {
            TrayFlyouts.shared.toggle(.calendar)
        }
        self.clockItem = clockItem
        for kind in [TrayItemKind.network, .volume, .battery] {
            TrayFlyouts.shared.register(kind) { [weak cluster] in cluster }
        }
        TrayFlyouts.shared.register(.calendar) { [weak clockItem] in clockItem }
        addArrangedSubview(appsView)
        addArrangedSubview(drivesItem.view)
        addArrangedSubview(cluster)
        addArrangedSubview(clockItem)
        TrayFlyouts.shared.register(.apps) { [weak self] in
            guard let self else { return nil }
            return self.appsView.isHidden ? self : self.appsView
        }

        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func refresh() {
        let now = Date()
        let separator = clockOnOneLine ? "  " : "\n"
        clock.stringValue = timeFormatter.string(from: now) + separator + dateFormatter.string(from: now)
        clockItem?.toolTip = longDateFormatter.string(from: now)
        clockItem?.invalidateIntrinsicContentSize()
    }

    private static func item(_ views: [NSView], height: DSControlHeight, tip: String, pane: String) -> DSButton {
        let item = DSButton(views: views, height: height, tip: tip)
        item.onPress = {
            TraySettings.open(pane)
        }
        return item
    }
}
