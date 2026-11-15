import AppKit
import HoboshellCore

final class TrayClusterButton: DSButton {
    private let networkIcon = DSIconView(side: DSIconSize.inline)
    private let volumeIcon = DSIconView(side: DSIconSize.inline)
    private let batteryIcon = DSIconView(side: DSIconSize.inline)
    private var scroll = TrayScrollAccumulator()
    private var networkText = ""
    private var volumeText: String?
    private var batteryText: String?
    private var observers: [NSObjectProtocol] = []
    private var powerWatcher: TrayPowerWatcher?

    init(height: DSControlHeight) {
        let icons = [networkIcon, volumeIcon, batteryIcon]
        super.init(views: icons, height: height, tip: nil)
        setAccessibilityLabel("Quick settings")
        onPress = {
            TrayFlyouts.shared.toggle(.network)
        }
        TrayWiFi.shared.start()
        TrayNetwork.shared.start()
        TrayVolumeControl.shared.start()
        let center = NotificationCenter.default
        let reloads: [(Notification.Name, () -> Void)] = [
            (TrayWiFi.didChange, { [weak self] in self?.showNetwork() }),
            (TrayNetwork.didChange, { [weak self] in self?.showNetwork() }),
            (TrayVolumeControl.didChange, { [weak self] in self?.showVolume() }),
            (.NSProcessInfoPowerStateDidChange, { [weak self] in self?.showBattery() }),
        ]
        observers = reloads.map { name, reload in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in reload() }
        }
        powerWatcher = TrayPowerWatcher { [weak self] in
            self?.showBattery()
        }
        showNetwork()
        showVolume()
        showBattery()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    override func scrollWheel(with event: NSEvent) {
        DSTooltip.shared.dismiss()
        guard event.momentumPhase.isEmpty else { return }
        let direction: CGFloat = event.isDirectionInvertedFromDevice ? -1 : 1
        let steps = scroll.add(event.scrollingDeltaY * direction, isPrecise: event.hasPreciseScrollingDeltas)
        guard steps != 0, let state = TrayVolumeControl.shared.state() else { return }
        TrayVolumeControl.shared.setVolume(TrayVolume.stepped(state.level, by: steps))
    }

    private func showNetwork() {
        let wifi = TrayWiFi.shared
        let state = wifi.state
        let icon = NetworkIcon.resolve(
            isWiFiAvailable: state.isAvailable,
            isWiFiPoweredOn: state.isPoweredOn,
            isWiFiJoined: wifi.connection.isConnected,
            rssi: state.rssi,
            summary: TrayNetwork.shared.summary
        )
        networkText = icon.tooltipText(name: wifi.connection.name)
        networkIcon.image = DSIconSize.firstSymbol(icon.symbolNames, variableValue: icon.variableValue, description: "Network")
        networkIcon.contentTintColor = DSTrayTone.color(icon.tone)
        refreshTip()
    }

    private func showVolume() {
        let state = TrayVolumeControl.shared.state()
        let level = state?.level ?? 0
        let isMuted = state?.isMuted ?? false
        volumeText = state.map { _ in TrayClusterText.volume(level: level, isMuted: isMuted) }
        volumeIcon.image = DSIconSize.symbol(TrayVolume.symbol(level: level, isMuted: isMuted), description: "Volume")
        refreshTip()
    }

    private func showBattery() {
        guard let status = TrayBatteryReader.read()?.status else {
            batteryText = nil
            batteryIcon.isHidden = true
            refreshTip()
            return
        }
        let icon = BatteryIcon(status: status, isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled)
        batteryIcon.isHidden = false
        batteryIcon.image = DSIconSize.symbol(icon.symbolName, description: "Battery")
        batteryIcon.contentTintColor = DSTrayTone.color(icon.tone)
        batteryText = TrayClusterText.battery(status)
        refreshTip()
    }

    private func refreshTip() {
        toolTip = TrayClusterText.tooltip(network: networkText, volume: volumeText, battery: batteryText)
        invalidateIntrinsicContentSize()
    }
}
