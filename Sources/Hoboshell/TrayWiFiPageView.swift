import AppKit
import HoboshellCore

final class TrayWiFiPageView: NSView {
    var onBack: (() -> Void)?

    private let context: TrayFlyoutContext
    private let powerSwitch = DSSwitch()
    private let statusLabel = DSLabel("", color: DSColor.dimText)
    private let permissionLabel = DSLabel("Network names are hidden.", color: DSColor.dimText)
    private let allowButton = DSButton(title: "Allow network names", height: .regular)
    private let permissionRow = NSStackView()
    private lazy var statusRow = Self.inset(statusLabel)
    private lazy var emptyRow = Self.inset(emptyLabel)
    private let currentRow = DSNetworkRow(isCurrent: true)
    private let othersHeader = DSSectionHeader("Other networks")
    private let rowsStack = NSStackView()
    private lazy var rows = KeyedStack<DSNetworkRow>(stack: rowsStack)
    private let emptyLabel = DSLabel("", color: DSColor.dimText)
    private var observers: [NSObjectProtocol] = []

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        let backButton = DSButton(symbol: "chevron.left", tip: "Back", height: .regular)
        backButton.onPress = { [weak self] in
            self?.onBack?()
        }
        let title = DSLabel("Wi-Fi", style: .title, weight: .semibold)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        powerSwitch.onToggle = { isOn in
            TrayWiFi.shared.setPower(isOn)
        }
        powerSwitch.setAccessibilityLabel("Wi-Fi")
        let header = NSStackView(views: [backButton, title, powerSwitch])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = DSSpacing.s
        header.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: DSSpacing.s)

        currentRow.makeStatic()
        permissionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        permissionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        allowButton.onPress = { [weak self] in
            if TrayLocationAccess.shared.allow() {
                self?.context.dismiss()
            }
        }
        permissionRow.addArrangedSubview(permissionLabel)
        permissionRow.addArrangedSubview(allowButton)
        permissionRow.orientation = .horizontal
        permissionRow.alignment = .centerY
        permissionRow.spacing = DSSpacing.s
        permissionRow.edgeInsets = Self.rowInsets

        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = DSSpacing.xxs

        let all = TrayFlyoutStack.make([
            header, statusRow, permissionRow, currentRow, othersHeader, rowsStack, emptyRow, DSDivider(),
            TraySettings.button(title: "Wi-Fi settings", pane: TraySettings.network, context: context),
        ], spacing: DSSpacing.xs)
        all.translatesAutoresizingMaskIntoConstraints = false
        addSubview(all)
        NSLayoutConstraint.activate([
            all.leadingAnchor.constraint(equalTo: leadingAnchor),
            all.trailingAnchor.constraint(equalTo: trailingAnchor),
            all.topAnchor.constraint(equalTo: topAnchor),
            all.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        let onChange: (Notification) -> Void = { [weak self] _ in
            self?.reload()
        }
        observers = [
            NotificationCenter.default.addObserver(forName: TrayWiFi.didChange, object: nil, queue: .main, using: onChange),
            NotificationCenter.default.addObserver(forName: TrayLocationAccess.didChange, object: nil, queue: .main, using: onChange),
        ]
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func reload() {
        let wifi = TrayWiFi.shared
        let state = wifi.state
        let showsNames = state.isPoweredOn && TrayLocationAccess.shared.isGranted
        powerSwitch.isOn = state.isPoweredOn
        powerSwitch.isEnabled = state.isAvailable

        let status = Self.statusText(for: state, isConnected: wifi.isConnected, showsNames: showsNames)
        statusLabel.stringValue = status ?? ""
        statusRow.isHidden = status == nil
        permissionRow.isHidden = !(state.isPoweredOn && !showsNames)

        let current = showsNames ? state.ssid : nil
        currentRow.isHidden = current == nil
        if let current {
            let isSecured = wifi.scanned.first { $0.name == current }?.isSecured ?? false
            currentRow.update(name: current, bars: WiFiSignal.bars(rssi: state.rssi), isSecured: isSecured, isCurrent: true)
        }

        let others = showsNames ? WiFiNetworks.others(from: wifi.scanned, excluding: state.ssid) : []
        let byName = Dictionary(others.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        othersHeader.isHidden = !showsNames
        rowsStack.isHidden = others.isEmpty
        rows.apply(
            keys: others.map(\.name),
            animated: false,
            make: { [weak self] _ in
                let row = DSNetworkRow()
                if let self {
                    row.widthAnchor.constraint(equalTo: self.rowsStack.widthAnchor).isActive = true
                }
                return row
            },
            update: { [weak self] row, name in
                guard let network = byName[name] else { return }
                row.update(name: network.name, bars: network.bars, isSecured: network.isSecured, isCurrent: false)
                row.onPress = { [weak self] in
                    self?.context.dismiss()
                    TraySettings.open(TraySettings.network)
                }
            }
        )
        emptyLabel.stringValue = wifi.isScanning ? "Scanning for networks..." : "No other networks found."
        emptyRow.isHidden = !showsNames || !others.isEmpty
        context.refit()
    }

    private static let rowInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: DSSpacing.s)

    private static func inset(_ label: DSLabel) -> NSStackView {
        let row = NSStackView(views: [label])
        row.edgeInsets = rowInsets
        return row
    }

    private static func statusText(for state: TrayWiFi.State, isConnected: Bool, showsNames: Bool) -> String? {
        if !state.isAvailable { return "This Mac has no Wi-Fi." }
        if !state.isPoweredOn { return "Wi-Fi is off." }
        if !showsNames { return QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: isConnected, name: nil) }
        return state.ssid == nil ? QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: isConnected, name: nil) : nil
    }
}
