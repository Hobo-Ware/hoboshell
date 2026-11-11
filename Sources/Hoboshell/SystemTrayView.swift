import AppKit
import HoboshellCore
import IOKit.ps
import Network

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5

    private let networkIcon = NSImageView()
    private let batteryIcon = NSImageView()
    private let batteryLabel = NSTextField(labelWithString: "")
    private let clock = NSTextField(labelWithString: "")
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let networkMonitor = NWPathMonitor()
    private var refreshTimer: Timer?

    private let clockOnOneLine: Bool

    init(clockOnOneLine: Bool) {
        self.clockOnOneLine = clockOnOneLine
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 8
        timeFormatter.dateFormat = "HH:mm"
        dateFormatter.dateStyle = .short

        for icon in [networkIcon, batteryIcon] {
            icon.contentTintColor = .white
            icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        }
        batteryLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        clock.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        clock.alignment = .right
        clock.maximumNumberOfLines = clockOnOneLine ? 1 : 2

        [networkIcon, batteryIcon, batteryLabel, clock].forEach(addArrangedSubview)

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
        networkIcon.image = NSImage(systemSymbolName: isOnline ? "wifi" : "wifi.slash", accessibilityDescription: "Network")
        networkIcon.toolTip = isOnline ? "Connected" : "No connection"
    }

    private func refresh() {
        let now = Date()
        let separator = clockOnOneLine ? "  " : "\n"
        clock.stringValue = timeFormatter.string(from: now) + separator + dateFormatter.string(from: now)

        let battery = Self.readBattery()
        batteryIcon.isHidden = battery == nil
        batteryLabel.isHidden = battery == nil
        if let battery {
            batteryIcon.image = NSImage(systemSymbolName: battery.symbolName, accessibilityDescription: "Battery")
            batteryLabel.stringValue = battery.label
        }
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
