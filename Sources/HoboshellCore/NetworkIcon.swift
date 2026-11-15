public enum NetworkIcon: Equatable {
    case wifi(bars: Int)
    case wifiNotJoined
    case wifiOff
    case noInternet
    case wired
    case otherLink
    case offline

    public static let weakestBars = 1

    public static func resolve(
        isWiFiAvailable: Bool,
        isWiFiPoweredOn: Bool,
        isWiFiJoined: Bool,
        rssi: Int,
        summary: NetworkSummary
    ) -> NetworkIcon {
        if summary.isOnline, summary.link == .wired { return .wired }
        guard isWiFiAvailable else { return summary.isOnline ? .otherLink : .offline }
        guard isWiFiPoweredOn else { return summary.isOnline ? .otherLink : .wifiOff }
        guard isWiFiJoined else { return summary.isOnline ? .otherLink : .wifiNotJoined }
        guard summary.isOnline else { return .noInternet }
        return .wifi(bars: min(max(WiFiSignal.bars(rssi: rssi), weakestBars), WiFiSignal.maxBars))
    }

    public var symbolNames: [String] {
        switch self {
        case .wifi, .wifiNotJoined: return ["wifi"]
        case .wifiOff, .offline: return ["wifi.slash"]
        case .noInternet: return ["wifi.exclamationmark"]
        case .wired: return ["cable.connector", "network"]
        case .otherLink: return ["network"]
        }
    }

    public var variableValue: Double? {
        switch self {
        case .wifi(let bars): return Double(bars) / Double(WiFiSignal.maxBars)
        case .wifiNotJoined: return 0
        default: return nil
        }
    }

    public var tone: TrayTone {
        self == .noInternet ? .warning : .normal
    }

    public func tooltipText(name: String?) -> String {
        switch self {
        case .wifi:
            guard let name, !name.isEmpty else { return "Wi-Fi connected" }
            return "Wi-Fi: \(name)"
        case .wifiNotJoined: return "Wi-Fi: not connected"
        case .wifiOff: return "Wi-Fi: off"
        case .noInternet: return "Wi-Fi: no internet"
        case .wired: return "Wired network"
        case .otherLink: return "Network connected"
        case .offline: return "Offline"
        }
    }
}
