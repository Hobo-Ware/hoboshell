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
    private var batteryItem: TrayItemView?

    init(clockOnOneLine: Bool) {
        self.clockOnOneLine = clockOnOneLine
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 2
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

        batteryItem = TrayItemView([batteryIcon, batteryLabel], tip: "Battery settings") {
            Self.openSettings(Self.batterySettings)
        }
        addArrangedSubview(TrayItemView([networkIcon], tip: "Network settings") {
            Self.openSettings(Self.networkSettings)
        })
        if let batteryItem {
            addArrangedSubview(batteryItem)
        }
        addArrangedSubview(TrayItemView([clock], tip: "Date and time settings") {
            Self.openSettings(Self.dateSettings)
        })

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
    }

    private func refresh() {
        let now = Date()
        let separator = clockOnOneLine ? "  " : "\n"
        clock.stringValue = timeFormatter.string(from: now) + separator + dateFormatter.string(from: now)

        let battery = Self.readBattery()
        batteryItem?.isHidden = battery == nil
        if let battery {
            batteryIcon.image = NSImage(systemSymbolName: battery.symbolName, accessibilityDescription: "Battery")
            batteryLabel.stringValue = battery.label
        }
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

private final class TrayItemView: HoverView {
    private static let sidePadding: CGFloat = 8
    private static let edgePadding: CGFloat = 4

    private let onClick: () -> Void

    init(_ views: [NSView], tip: String, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
        toolTip = tip
        translatesAutoresizingMaskIntoConstraints = false

        let content = NSStackView(views: views)
        content.orientation = .horizontal
        content.spacing = 6
        content.setHuggingPriority(.required, for: .horizontal)
        views.forEach { $0.setContentHuggingPriority(.required, for: .horizontal) }
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.sidePadding),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.sidePadding),
            content.topAnchor.constraint(equalTo: topAnchor, constant: Self.edgePadding),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.edgePadding),
        ])
    }

    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onClick()
        }
    }
}
