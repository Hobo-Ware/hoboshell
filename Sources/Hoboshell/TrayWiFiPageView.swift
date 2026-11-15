import AppKit
import HoboshellCore

final class TrayWiFiPageView: NSView {
    private static let rowInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: DSSpacing.s)
    private static let hiddenNamesText = "macOS hides network names until you allow Location."

    var onBack: (() -> Void)?

    private let context: TrayFlyoutContext
    private let powerSwitch = DSSwitch()
    private let statusLabel = DSLabel("", color: DSColor.dimText)
    private let allowButton = DSButton(title: "Allow network names", height: .regular)
    private let refreshButton = DSButton(symbol: "arrow.clockwise", tip: "Look for networks again", height: .regular)
    private let spinner = NSProgressIndicator()
    private let lookingLabel = DSLabel("Looking for networks...", color: DSColor.dimText)
    private let emptyLabel = DSLabel("", color: DSColor.dimText)
    private lazy var statusRow = Self.inset(statusLabel)
    private lazy var permissionRow = Self.inset(allowButton)
    private lazy var lookingStack = NSStackView(views: [spinner, lookingLabel])
    private lazy var lookingRow = Self.inset(lookingStack)
    private lazy var emptyRow = Self.inset(emptyLabel)
    private let currentRow = DSNetworkRow(isCurrent: true)
    private let othersHeader = DSSectionHeader(WiFiNetworksPage.Heading.otherNetworks.title)
    private let nearbyHeader = DSSectionHeader(WiFiNetworksPage.Heading.networksNearby.title)
    private let rowsStack = NSStackView()
    private lazy var rows = KeyedStack<DSNetworkRow>(stack: rowsStack)
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
        currentRow.onDisconnect = {
            TrayWiFi.shared.disconnect()
        }
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = TrayQuickSettingsView.contentWidth - DSSpacing.s * 2
        allowButton.onPress = { [weak self] in
            if TrayLocationAccess.shared.allow() {
                self?.context.dismiss()
            }
        }
        refreshButton.onPress = {
            TrayWiFi.shared.scan()
        }
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isIndeterminate = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        lookingStack.spacing = DSSpacing.s
        lookingStack.alignment = .centerY

        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = DSSpacing.xxs

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let settings = TraySettings.button(title: "Wi-Fi settings", pane: TraySettings.network, context: context)
        let footer = NSStackView(views: [settings, spacer, refreshButton])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = DSSpacing.s

        let all = TrayFlyoutStack.make([
            header, statusRow, permissionRow, currentRow, othersHeader, nearbyHeader, rowsStack, lookingRow, emptyRow, DSDivider(), footer,
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
        powerSwitch.isOn = state.isPoweredOn
        powerSwitch.isEnabled = state.isAvailable
        refreshButton.isEnabled = state.isPoweredOn && !wifi.isScanning

        let page = WiFiPage.make(
            isAvailable: state.isAvailable,
            connection: wifi.connection,
            namesAllowed: TrayLocationAccess.shared.isGranted,
            isScanning: wifi.isScanning,
            rssi: state.rssi,
            scanned: wifi.scanned
        )
        show(page)
        context.refit()
    }

    private func show(_ page: WiFiPage) {
        var status: String?
        var needsPermission = false
        var networks: WiFiNetworksPage?
        switch page {
        case .unavailable:
            status = "This Mac has no Wi-Fi."
        case .off:
            status = "Wi-Fi is off. Turn it on to see networks."
        case .namesHidden(let isConnected):
            status = isConnected ? "Connected. \(Self.hiddenNamesText)" : Self.hiddenNamesText
            needsPermission = true
        case .networks(let listed):
            networks = listed
        }
        statusLabel.stringValue = status ?? ""
        statusRow.isHidden = status == nil
        permissionRow.isHidden = !needsPermission
        showCurrent(networks?.current)
        showOthers(networks)
        let isScanning = networks?.progress == .scanning
        lookingRow.isHidden = !isScanning
        spinner.isHidden = DSMotion.isReduced
        if isScanning, !DSMotion.isReduced {
            spinner.startAnimation(nil)
        } else {
            spinner.stopAnimation(nil)
        }
        emptyLabel.stringValue = networks?.current == nil ? "No networks found." : "No other networks found."
        emptyRow.isHidden = networks?.progress != .nothingFound
    }

    private func showCurrent(_ current: WiFiCurrentNetwork?) {
        currentRow.isHidden = current == nil
        guard let current else { return }
        currentRow.update(
            name: current.name, bars: current.bars, isSecured: current.isSecured ?? false, isCurrent: true, status: current.statusText
        )
    }

    private func showOthers(_ page: WiFiNetworksPage?) {
        let others = page?.others ?? []
        let byName = Dictionary(others.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        othersHeader.isHidden = others.isEmpty || page?.heading != .otherNetworks
        nearbyHeader.isHidden = others.isEmpty || page?.heading != .networksNearby
        rowsStack.isHidden = others.isEmpty
        var newRowWidths: [NSLayoutConstraint] = []
        rows.apply(
            keys: others.map(\.name),
            animated: false,
            make: { _ in
                let row = DSNetworkRow()
                newRowWidths.append(row.widthAnchor.constraint(equalTo: rowsStack.widthAnchor))
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
        NSLayoutConstraint.activate(newRowWidths)
    }

    private static func inset(_ view: NSView) -> NSStackView {
        let row = NSStackView(views: [view])
        row.edgeInsets = rowInsets
        return row
    }
}
