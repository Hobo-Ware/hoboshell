public struct WiFiScanResult: Equatable {
    public let name: String
    public let rssi: Int
    public let isSecured: Bool

    public init(name: String, rssi: Int, isSecured: Bool) {
        self.name = name
        self.rssi = rssi
        self.isSecured = isSecured
    }
}

public struct WiFiNetwork: Equatable {
    public let name: String
    public let rssi: Int
    public let isSecured: Bool

    public var bars: Int { WiFiSignal.bars(rssi: rssi) }
}

public enum WiFiSignal {
    public static let maxBars = 3

    public static func bars(rssi: Int) -> Int {
        switch rssi {
        case (-60)...: return 3
        case (-70)...: return 2
        case (-80)...: return 1
        default: return 0
        }
    }
}

public enum WiFiNetworks {
    public static let maxShown = 8

    public static func others(from scanned: [WiFiScanResult], excluding current: String?, limit: Int = maxShown) -> [WiFiNetwork] {
        var strongest: [String: WiFiScanResult] = [:]
        for result in scanned where !result.name.isEmpty && result.name != current {
            if let existing = strongest[result.name], existing.rssi >= result.rssi {
                continue
            }
            strongest[result.name] = result
        }
        let ordered = strongest.values.sorted { first, second in
            if first.rssi != second.rssi { return first.rssi > second.rssi }
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
        return ordered.prefix(limit).map { WiFiNetwork(name: $0.name, rssi: $0.rssi, isSecured: $0.isSecured) }
    }
}
