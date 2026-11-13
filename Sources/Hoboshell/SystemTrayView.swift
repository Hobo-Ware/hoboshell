import AppKit
import HoboshellCore

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5

    private let networkIcon = DSIconView(side: DSIconSize.inline)
    private let volumeIcon = DSIconView(side: DSIconSize.inline)
    private let batteryIcon = DSIconView(side: DSIconSize.inline)
    private let batteryLabel = DSLabel(style: .caption, monospacedDigits: true)
    private let clock = DSLabel(style: .caption, monospacedDigits: true)
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let clockOnOneLine: Bool
    private var refreshTimer: Timer?
    private var trayItems: [DSButton] = []
    private var batteryItem: DSButton?
    private var volumeItem: DSButton?
    private var volumeObserver: NSObjectProtocol?
    private var networkObserver: NSObjectProtocol?
    private let appsView: TrayAppsView
    private let drivesItem: TrayDrivesItem

    init(clockOnOneLine: Bool, height: DSControlHeight) {
        self.clockOnOneLine = clockOnOneLine
        appsView = TrayAppsView(height: height)
        drivesItem = TrayDrivesItem(height: height)
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = DSSpacing.xs
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)
        timeFormatter.locale = .autoupdatingCurrent
        timeFormatter.timeStyle = .short
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.dateStyle = .short

        clock.alignment = .right
        clock.maximumNumberOfLines = clockOnOneLine ? 1 : 2

        let networkItem = DSButton(views: [networkIcon], height: height, tip: "Network")
        networkItem.onPress = {
            TrayFlyouts.shared.toggle(.network)
        }
        let volumeItem = TrayVolumeButton(views: [volumeIcon], height: height, tip: "Volume")
        volumeItem.onPress = {
            TrayFlyouts.shared.toggle(.volume)
        }
        let batteryItem = DSButton(views: [batteryIcon, batteryLabel], height: height, tip: "Battery")
        batteryItem.onPress = {
            TrayFlyouts.shared.toggle(.battery)
        }
        let clockItem = DSButton(views: [clock], height: height, tip: "Calendar")
        clockItem.onPress = {
            TrayFlyouts.shared.toggle(.calendar)
        }
        self.batteryItem = batteryItem
        trayItems = [networkItem, volumeItem, batteryItem, clockItem]
        self.volumeItem = volumeItem
        TrayFlyouts.shared.register(.network) { [weak networkItem] in networkItem }
        TrayFlyouts.shared.register(.battery) { [weak self, weak batteryItem] in
            batteryItem?.isHidden == false ? batteryItem : self
        }
        TrayFlyouts.shared.register(.calendar) { [weak clockItem] in clockItem }
        addArrangedSubview(appsView)
        addArrangedSubview(drivesItem.view)
        trayItems.forEach(addArrangedSubview)
        TrayFlyouts.shared.register(.apps) { [weak self] in
            guard let self else { return nil }
            return self.appsView.isHidden ? self : self.appsView
        }

        TrayFlyouts.shared.register(.volume) { [weak volumeItem] in volumeItem }
        TrayVolumeControl.shared.start()
        volumeObserver = NotificationCenter.default.addObserver(
            forName: TrayVolumeControl.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.showVolume()
        }
        showVolume()

        TrayNetwork.shared.start()
        networkObserver = NotificationCenter.default.addObserver(
            forName: TrayNetwork.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.showNetwork()
        }
        showNetwork()

        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        for observer in [volumeObserver, networkObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func showNetwork() {
        networkIcon.image = DSIconSize.symbol(TrayNetwork.shared.summary.symbolName, description: "Network")
    }

    private func showVolume() {
        let state = TrayVolumeControl.shared.state()
        let level = state?.level ?? 0
        let isMuted = state?.isMuted ?? false
        volumeIcon.image = DSIconSize.symbol(TrayVolume.symbol(level: level, isMuted: isMuted), description: "Volume")
        volumeItem?.toolTip = isMuted ? "Volume (muted)" : "Volume \(TrayVolume.percentText(level))"
    }

    private func refresh() {
        let now = Date()
        let separator = clockOnOneLine ? "  " : "\n"
        clock.stringValue = timeFormatter.string(from: now) + separator + dateFormatter.string(from: now)

        let battery = TrayBatteryReader.read()?.status
        batteryItem?.isHidden = battery == nil
        if let battery {
            batteryIcon.image = DSIconSize.symbol(battery.symbolName, description: "Battery")
            batteryLabel.stringValue = battery.label
        }
        trayItems.forEach { $0.invalidateIntrinsicContentSize() }
    }

    private static func item(_ views: [NSView], height: DSControlHeight, tip: String, pane: String) -> DSButton {
        let item = DSButton(views: views, height: height, tip: tip)
        item.onPress = {
            TraySettings.open(pane)
        }
        return item
    }
}
