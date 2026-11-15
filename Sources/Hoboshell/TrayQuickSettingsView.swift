import AppKit
import CoreAudio
import HoboshellCore

final class TrayQuickSettingsView: NSView {
    static let contentWidth: CGFloat = 360

    private let context: TrayFlyoutContext
    private let requestsLocation: Bool
    private let wifiPage: TrayWiFiPageView
    private let mainPage = NSStackView()

    private let wifiTile = TrayQuickTile(symbol: "wifi", title: "Wi-Fi", accessory: .arrow(tip: "Wi-Fi networks"))
    private let bluetoothTile = TrayQuickTile(symbol: "dot.radiowaves.left.and.right", title: "Bluetooth", accessory: .opensSettings)
    private let lowPowerTile = TrayQuickTile(symbol: "leaf", title: "Low Power", accessory: .opensSettings)
    private let darkTile = TrayQuickTile(symbol: "circle.lefthalf.filled", title: "Dark mode", accessory: .opensSettings)
    private let focusTile = TrayQuickTile(symbol: "moon.fill", title: "Focus", accessory: .opensSettings)
    private let keyboardTile = TrayQuickTile(symbol: "keyboard", title: "Keyboard")

    private let errorLabel = DSLabel("")
    private lazy var errorRow = makeErrorRow()

    private let muteButton = DSButton(symbol: "speaker.fill", tip: "Mute", height: .regular)
    private let slider = DSSlider()
    private let outputsButton = DSButton(symbol: "chevron.down", tip: "Sound outputs", height: .regular)
    private let devicesStack = NSStackView()
    private lazy var devices = KeyedStack<DSListRow>(stack: devicesStack)
    private lazy var devicesSection = TrayFlyoutStack.make([DSSectionHeader("Output"), devicesStack])
    private var showsDevices = false

    private let batteryIcon = DSIconView(side: DSIconSize.inline)
    private let batteryLabel = DSLabel("", monospacedDigits: true)
    private lazy var batteryButton = DSButton(views: [batteryIcon, batteryLabel], height: .row, tip: "Battery")
    private let addressLabel = DSLabel("", color: DSColor.dimText, monospacedDigits: true)

    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []
    private var powerWatcher: TrayPowerWatcher?

    init(context: TrayFlyoutContext, opensWiFiPage: Bool, requestsLocation: Bool) {
        self.context = context
        self.requestsLocation = requestsLocation
        wifiPage = TrayWiFiPageView(context: context)
        super.init(frame: .zero)
        TrayWiFi.shared.start()
        TrayNetwork.shared.start()
        TrayVolumeControl.shared.start()
        buildMainPage()
        wifiPage.onBack = { [weak self] in
            self?.showMainPage()
        }

        let pages = NSStackView(views: [mainPage, wifiPage])
        pages.orientation = .vertical
        pages.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pages)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.contentWidth),
            pages.leadingAnchor.constraint(equalTo: leadingAnchor),
            pages.trailingAnchor.constraint(equalTo: trailingAnchor),
            pages.topAnchor.constraint(equalTo: topAnchor),
            pages.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        mainPage.widthAnchor.constraint(equalTo: pages.widthAnchor).isActive = true
        wifiPage.widthAnchor.constraint(equalTo: pages.widthAnchor).isActive = true

        reloadAll()
        observe()
        if opensWiFiPage {
            showWiFiPage()
        } else {
            wifiPage.isHidden = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        for observer in observers {
            observer.center.removeObserver(observer.token)
        }
    }

    private func showWiFiPage() {
        if requestsLocation {
            TrayLocationAccess.shared.requestIfUndecided()
        }
        TrayWiFi.shared.scan()
        wifiPage.reload()
        mainPage.isHidden = true
        wifiPage.isHidden = false
        context.refit()
    }

    private func showMainPage() {
        wifiPage.isHidden = true
        mainPage.isHidden = false
        context.refit()
    }

    private func buildMainPage() {
        wifiTile.onPress = {
            TrayWiFi.shared.setPower(!TrayWiFi.shared.state.isPoweredOn)
        }
        wifiTile.onArrow = { [weak self] in
            self?.showWiFiPage()
        }
        bluetoothTile.onPress = { [weak self] in self?.openSettings(TraySettings.bluetooth) }
        lowPowerTile.onPress = { [weak self] in self?.openSettings(TraySettings.battery) }
        darkTile.onPress = { [weak self] in self?.openSettings(TraySettings.appearance) }
        focusTile.onPress = { [weak self] in self?.openSettings(TraySettings.focus) }
        keyboardTile.onPress = {
            TrayInputSource.selectNext()
        }

        slider.onChange = { value in
            TrayVolumeControl.shared.setVolume(Float(value))
        }
        muteButton.onPress = {
            guard let state = TrayVolumeControl.shared.state() else { return }
            TrayVolumeControl.shared.setMuted(!state.isMuted)
        }
        outputsButton.onPress = { [weak self] in
            self?.toggleDevices()
        }
        devicesStack.orientation = .vertical
        devicesStack.alignment = .leading
        devicesStack.spacing = DSSpacing.xxs
        devicesSection.isHidden = true

        let volume = NSStackView(views: [muteButton, slider, outputsButton])
        volume.orientation = .horizontal
        volume.spacing = DSSpacing.s
        volume.alignment = .centerY

        let tileRows = [[wifiTile, bluetoothTile, lowPowerTile], [darkTile, focusTile, keyboardTile]].map { group -> NSStackView in
            let row = NSStackView(views: group)
            row.orientation = .horizontal
            row.distribution = .fillEqually
            row.spacing = DSSpacing.s
            return row
        }

        let gear = DSButton(symbol: "gearshape", tip: "Network settings", height: .regular)
        gear.onPress = { [weak self] in
            self?.openSettings(TraySettings.network)
        }
        batteryButton.onPress = {
            TrayFlyouts.shared.show(.battery)
        }
        addressLabel.alignment = .center
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let footer = NSStackView(views: [batteryButton, addressLabel, gear])
        footer.orientation = .horizontal
        footer.spacing = DSSpacing.s
        footer.alignment = .centerY

        let rows: [NSView] = tileRows + [errorRow, DSDivider(), volume, devicesSection, DSDivider(), footer]
        let stack = TrayFlyoutStack.make(rows, spacing: DSSpacing.s)
        stack.translatesAutoresizingMaskIntoConstraints = false
        mainPage.orientation = .vertical
        mainPage.addArrangedSubview(stack)
        stack.widthAnchor.constraint(equalTo: mainPage.widthAnchor).isActive = true
    }

    private func makeErrorRow() -> NSView {
        let icon = DSIconView(side: DSIconSize.inline, image: DSIconSize.symbol("exclamationmark.triangle.fill"), tint: DSColor.danger)
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.maximumNumberOfLines = 0
        errorLabel.preferredMaxLayoutWidth = Self.contentWidth - DSIconSize.inline - DSSpacing.s * 3
        let row = NSStackView(views: [icon, errorLabel])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = DSSpacing.s
        row.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: DSSpacing.s)
        row.isHidden = true
        return row
    }

    private func openSettings(_ pane: String) {
        context.dismiss()
        TraySettings.open(pane)
    }

    private func toggleDevices() {
        showsDevices.toggle()
        outputsButton.isSelected = showsDevices
        devicesSection.isHidden = !showsDevices
        reloadVolume()
        context.refit()
    }

    private func observe() {
        let center = NotificationCenter.default
        let distributed = DistributedNotificationCenter.default()
        let add: (NotificationCenter, Notification.Name, @escaping () -> Void) -> Void = { [weak self] center, name, reload in
            let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
                reload()
            }
            self?.observers.append((center, token))
        }
        add(center, TrayWiFi.didChange) { [weak self] in self?.reloadWiFi() }
        add(center, TrayNetwork.didChange) { [weak self] in
            self?.reloadWiFi()
            self?.reloadAddress()
        }
        add(center, TrayVolumeControl.didChange) { [weak self] in self?.reloadVolume() }
        add(center, .NSProcessInfoPowerStateDidChange) { [weak self] in self?.reloadLowPower() }
        add(distributed, Notification.Name("AppleInterfaceThemeChangedNotification")) {
            DispatchQueue.main.async { [weak self] in self?.reloadAppearance() }
        }
        add(distributed, TrayInputSource.didChange) { [weak self] in self?.reloadKeyboard() }
        powerWatcher = TrayPowerWatcher { [weak self] in
            self?.reloadBattery()
        }
    }

    private func reloadAll() {
        reloadWiFi()
        reloadLowPower()
        reloadAppearance()
        reloadKeyboard()
        reloadVolume()
        reloadBattery()
        reloadAddress()
        bluetoothTile.update(symbol: "dot.radiowaves.left.and.right", title: "Bluetooth", label: "Bluetooth", detail: "")
        focusTile.update(symbol: "moon.fill", title: "Focus", label: "Focus", detail: "")
    }

    private func reloadWiFi() {
        let wifi = TrayWiFi.shared
        let state = wifi.state
        let connection = wifi.connection
        let detail = QuickSettingsText.wifiLabel(isPoweredOn: state.isPoweredOn, isConnected: connection.isConnected, name: connection.name)
        let label = QuickSettingsText.wifiTileLabel(isPoweredOn: state.isPoweredOn, isConnected: connection.isConnected, name: connection.name)
        wifiTile.update(symbol: state.isPoweredOn ? "wifi" : "wifi.slash", title: "Wi-Fi", label: label, detail: detail)
        wifiTile.isOn = state.isPoweredOn
        wifiTile.isEnabled = state.isAvailable
        let error = wifi.errorText
        errorLabel.stringValue = error ?? ""
        errorRow.isHidden = error == nil
        context.refit()
    }

    private func reloadLowPower() {
        reloadBattery()
        let isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
        lowPowerTile.update(symbol: "leaf", title: "Low Power", label: "Low Power", detail: QuickSettingsText.switchLabel(isOn: isOn))
        lowPowerTile.isOn = isOn
    }

    private func reloadAppearance() {
        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        darkTile.update(symbol: "circle.lefthalf.filled", title: "Dark mode", label: "Dark mode", detail: QuickSettingsText.appearanceLabel(isDark: isDark))
        darkTile.isOn = isDark
    }

    private func reloadKeyboard() {
        let layout = TrayInputSource.current()?.shortName ?? ""
        keyboardTile.update(symbol: "keyboard", title: "Keyboard", label: layout.isEmpty ? "Keyboard" : layout, detail: layout)
    }

    private func reloadVolume() {
        let state = TrayVolumeControl.shared.state()
        let level = state?.level ?? 0
        slider.doubleValue = Double(level)
        slider.isEnabled = state?.canSetVolume ?? false
        muteButton.image = DSIconSize.symbol(TrayVolume.symbol(level: level, isMuted: state?.isMuted ?? false), description: "Mute")
        muteButton.isSelected = state?.isMuted ?? false
        outputsButton.image = DSIconSize.symbol(showsDevices ? "chevron.up" : "chevron.down", description: "Sound outputs")
        guard showsDevices else { return }
        let outputs = state?.devices ?? []
        let byKey = Dictionary(outputs.map { (String($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        var newRowWidths: [NSLayoutConstraint] = []
        let diff = devices.apply(
            keys: outputs.map { String($0.id) },
            animated: false,
            make: { _ in
                let row = DSListRow(title: "", image: nil, height: .row)
                newRowWidths.append(row.widthAnchor.constraint(equalTo: devicesStack.widthAnchor))
                return row
            },
            update: { row, key in
                guard let device = byKey[key] else { return }
                let tick = device.id == state?.currentDeviceID
                    ? DSIconSize.symbol("checkmark")
                    : NSImage(size: NSSize(width: DSIconSize.row, height: DSIconSize.row))
                row.update(title: device.name, image: tick, detail: nil)
                row.onPress = {
                    TrayVolumeControl.shared.setOutputDevice(device.id)
                }
            }
        )
        NSLayoutConstraint.activate(newRowWidths)
        if !diff.inserted.isEmpty || !diff.removed.isEmpty {
            context.refit()
        }
    }

    private func reloadBattery() {
        let battery = TrayBatteryReader.read()?.status
        batteryButton.isHidden = battery == nil
        guard let battery else { return }
        let icon = BatteryIcon(status: battery, isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled)
        batteryIcon.image = DSIconSize.symbol(icon.symbolName, description: "Battery")
        batteryIcon.contentTintColor = DSTrayTone.color(icon.tone)
        batteryLabel.stringValue = battery.label
    }

    private func reloadAddress() {
        let summary = TrayNetwork.shared.summary
        addressLabel.stringValue = summary.isOnline ? TrayNetwork.shared.localAddress() ?? "" : "Offline"
    }
}
