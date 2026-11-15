import CoreWLAN
import Foundation
import HoboshellCore
import os

final class TrayWiFi: NSObject, CWEventDelegate {
    struct State: Equatable {
        var isAvailable = false
        var isPoweredOn = false
        var ssid: String?
        var rssi = 0

        static func == (first: State, second: State) -> Bool {
            first.isAvailable == second.isAvailable
                && first.isPoweredOn == second.isPoweredOn
                && first.ssid == second.ssid
                && (first.rssi == 0) == (second.rssi == 0)
                && WiFiSignal.bars(rssi: first.rssi) == WiFiSignal.bars(rssi: second.rssi)
        }
    }

    static let shared = TrayWiFi()
    static let didChange = Notification.Name("HoboshellTrayWiFiDidChange")

    private static let log = Logger(subsystem: "dev.hoboware.hoboshell", category: "wifi")

    private(set) var state = State()
    private(set) var scanned: [WiFiScanResult] = []
    private(set) var isScanning = false
    private(set) var errorText: String?

    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.wifi", qos: .userInitiated)
    private var isStarted = false

    var connection: WiFiConnection {
        let summary = TrayNetwork.shared.summary
        let hasLink = state.rssi != 0 || (summary.isOnline && summary.link == .wifi)
        return WiFiConnection.resolve(isPoweredOn: state.isPoweredOn, ssid: state.ssid, hasLink: hasLink)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        let client = CWWiFiClient.shared()
        client.delegate = self
        for event in [CWEventType.powerDidChange, .ssidDidChange, .linkDidChange, .linkQualityDidChange, .scanCacheUpdated] {
            do {
                try client.startMonitoringEvent(with: event)
            } catch {
                Self.log.error("could not watch Wi-Fi events: \(error.localizedDescription, privacy: .public)")
            }
        }
        refreshState()
    }

    func setPower(_ isOn: Bool) {
        errorText = nil
        queue.async { [weak self] in
            do {
                try CWWiFiClient.shared().interface()?.setPower(isOn)
                self?.refreshState()
            } catch {
                let text = "macOS would not turn Wi-Fi \(isOn ? "on" : "off"): \(error.localizedDescription)"
                DispatchQueue.main.async {
                    self?.errorText = text
                    self?.announce()
                }
            }
        }
    }

    func disconnect() {
        queue.async { [weak self] in
            CWWiFiClient.shared().interface()?.disassociate()
            self?.refreshState()
        }
    }

    func scan() {
        guard state.isPoweredOn, !isScanning else { return }
        isScanning = true
        announce()
        queue.async { [weak self] in
            let results: [WiFiScanResult]
            do {
                let found = try CWWiFiClient.shared().interface()?.scanForNetworks(withSSID: nil) ?? []
                results = Self.results(from: found)
            } catch {
                Self.log.error("Wi-Fi scan failed: \(error.localizedDescription, privacy: .public)")
                results = []
            }
            DispatchQueue.main.async {
                self?.isScanning = false
                self?.scanned = results
                self?.announce()
            }
        }
    }

    func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        refreshState()
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        refreshState()
    }

    func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        refreshState()
    }

    func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        refreshState()
    }

    func scanCacheUpdatedForWiFiInterface(withName interfaceName: String) {
        queue.async { [weak self] in
            let cached = CWWiFiClient.shared().interface()?.cachedScanResults() ?? []
            let results = Self.results(from: cached)
            DispatchQueue.main.async {
                guard let self, results != self.scanned else { return }
                self.scanned = results
                self.announce()
            }
        }
    }

    private func refreshState() {
        queue.async { [weak self] in
            let next = Self.readState()
            DispatchQueue.main.async {
                guard let self, next != self.state else { return }
                self.state = next
                self.errorText = nil
                self.announce()
            }
        }
    }

    private func announce() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }

    private static func readState() -> State {
        guard let interface = CWWiFiClient.shared().interface() else { return State() }
        return State(isAvailable: true, isPoweredOn: interface.powerOn(), ssid: interface.ssid(), rssi: interface.rssiValue())
    }

    private static func results(from networks: Set<CWNetwork>) -> [WiFiScanResult] {
        networks.compactMap { network in
            network.ssid.map { WiFiScanResult(name: $0, rssi: network.rssiValue, isSecured: !network.supportsSecurity(.none)) }
        }
    }
}
