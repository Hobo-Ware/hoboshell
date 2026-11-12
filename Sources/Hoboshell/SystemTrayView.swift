import AppKit
import HoboshellCore
import IOKit.ps
import Network

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5

    private let networkIcon = DSIconView(side: DSIconSize.inline)
    private let volumeIcon = DSIconView(side: DSIconSize.inline)
    private let batteryIcon = DSIconView(side: DSIconSize.inline)
    private let batteryLabel = DSLabel(style: .caption, monospacedDigits: true)
    private let clock = DSLabel(style: .caption, monospacedDigits: true)
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let networkMonitor = NWPathMonitor()
    private let clockOnOneLine: Bool
    private var refreshTimer: Timer?
    private var trayItems: [DSButton] = []
    private var batteryItem: DSButton?
    private var volumeItem: DSButton?
    private var volumeObserver: NSObjectProtocol?
    private let appsView: TrayAppsView

    init(clockOnOneLine: Bool, height: DSControlHeight) {
        self.clockOnOneLine = clockOnOneLine
        appsView = TrayAppsView(height: height)
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

        let networkItem = Self.item([networkIcon], height: height, tip: "Network settings", pane: TraySettings.network)
        let volumeItem = TrayVolumeButton(views: [volumeIcon], height: height, tip: "Volume")
        volumeItem.onPress = {
            TrayFlyouts.shared.toggle(.volume)
        }
        let batteryItem = Self.item([batteryIcon, batteryLabel], height: height, tip: "Battery settings", pane: TraySettings.battery)
        let clockItem = DSButton(views: [clock], height: height, tip: "Calendar")
        clockItem.onPress = {
            TrayFlyouts.shared.toggle(.calendar)
        }
        self.batteryItem = batteryItem
        trayItems = [networkItem, volumeItem, batteryItem, clockItem]
        self.volumeItem = volumeItem
        TrayFlyouts.shared.register(.calendar) { [weak clockItem] in clockItem }
        addArrangedSubview(appsView)
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

        showNetwork(isOnline: true)
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            DispatchQueue.main.async {
                self?.showNetwork(isOnline: isOnline)
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "dev.hoboware.hoboshell.network"))

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
        networkMonitor.cancel()
        if let volumeObserver {
            NotificationCenter.default.removeObserver(volumeObserver)
        }
    }

    private func showNetwork(isOnline: Bool) {
        networkIcon.image = DSIconSize.symbol(isOnline ? "wifi" : "wifi.slash", description: "Network")
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

        let battery = Self.readBattery()
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

    private static func readBattery() -> BatteryStatus? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let details = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  let current = details[kIOPSCurrentCapacityKey] as? Int,
                  let capacity = details[kIOPSMaxCapacityKey] as? Int,
                  capacity > 0 else { continue }
            return BatteryStatus(
                percent: current * 100 / capacity,
                isCharging: details[kIOPSIsChargingKey] as? Bool ?? false
            )
        }
        return nil
    }
}
