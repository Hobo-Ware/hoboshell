import AppKit
import HoboshellCore
import IOKit.ps
import Network

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5
    private static let networkSettings = "x-apple.systempreferences:com.apple.wifi-settings-extension"
    private static let batterySettings = "x-apple.systempreferences:com.apple.Battery-Settings.extension"
    private static let dateSettings = "x-apple.systempreferences:com.apple.Date-Time-Settings.extension"

    private let networkIcon = DSIconView(side: DSIconSize.inline)
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

    init(clockOnOneLine: Bool, height: DSControlHeight) {
        self.clockOnOneLine = clockOnOneLine
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = DSSpacing.xs
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)
        timeFormatter.dateFormat = "HH:mm"
        dateFormatter.dateStyle = .short

        clock.alignment = .right
        clock.maximumNumberOfLines = clockOnOneLine ? 1 : 2

        let networkItem = Self.item([networkIcon], height: height, tip: "Network settings", pane: Self.networkSettings)
        let batteryItem = Self.item([batteryIcon, batteryLabel], height: height, tip: "Battery settings", pane: Self.batterySettings)
        let clockItem = Self.item([clock], height: height, tip: "Date and time settings", pane: Self.dateSettings)
        self.batteryItem = batteryItem
        trayItems = [networkItem, batteryItem, clockItem]
        trayItems.forEach(addArrangedSubview)

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
    }

    private func showNetwork(isOnline: Bool) {
        networkIcon.image = DSIconSize.symbol(isOnline ? "wifi" : "wifi.slash", description: "Network")
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
            openSettings(pane)
        }
        return item
    }

    private static func openSettings(_ pane: String) {
        guard let url = URL(string: pane) else { return }
        NSWorkspace.shared.open(url)
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
