import AppKit
import HoboshellCore
import IOKit.ps
import Network

final class SystemTrayView: NSStackView {
    private static let refreshInterval: TimeInterval = 5
    private static let networkSettings = "x-apple.systempreferences:com.apple.wifi-settings-extension"
    private static let batterySettings = "x-apple.systempreferences:com.apple.Battery-Settings.extension"
    private static let dateSettings = "x-apple.systempreferences:com.apple.Date-Time-Settings.extension"

    private let networkIcon = NSImageView()
    private let batteryIcon = NSImageView()
    private let batteryLabel = NSTextField(labelWithString: "")
    private let clock = NSTextField(labelWithString: "")
    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let networkMonitor = NWPathMonitor()
    private let clockOnOneLine: Bool
    private var refreshTimer: Timer?

    init(clockOnOneLine: Bool) {
        self.clockOnOneLine = clockOnOneLine
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 8
        setHuggingPriority(.required, for: .horizontal)
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

        open(#selector(openNetworkSettings), whenClicking: networkIcon, tip: "Network settings")
        open(#selector(openBatterySettings), whenClicking: batteryIcon, tip: "Battery settings")
        open(#selector(openBatterySettings), whenClicking: batteryLabel, tip: "Battery settings")
        open(#selector(openDateSettings), whenClicking: clock, tip: "Date and time settings")

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

    private func open(_ action: Selector, whenClicking view: NSView, tip: String) {
        view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: action))
        view.toolTip = tip
    }

    private func showNetwork(isOnline: Bool) {
        networkIcon.image = NSImage(systemSymbolName: isOnline ? "wifi" : "wifi.slash", accessibilityDescription: "Network")
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

    private static func openSettings(_ pane: String) {
        guard let url = URL(string: pane) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func openNetworkSettings() {
        Self.openSettings(Self.networkSettings)
    }

    @objc private func openBatterySettings() {
        Self.openSettings(Self.batterySettings)
    }

    @objc private func openDateSettings() {
        Self.openSettings(Self.dateSettings)
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
