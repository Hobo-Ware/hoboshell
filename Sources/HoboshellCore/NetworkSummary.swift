public enum NetworkLinkKind: Equatable {
    case wifi
    case wired
    case cellular
    case other
}

public struct NetworkSummary: Equatable {
    public let isOnline: Bool
    public let link: NetworkLinkKind

    public init(isOnline: Bool, link: NetworkLinkKind) {
        self.isOnline = isOnline
        self.link = link
    }

    public var statusText: String { isOnline ? "Connected" : "Offline" }

    public var kindText: String? {
        guard isOnline else { return nil }
        switch link {
        case .wifi: return "Wi-Fi"
        case .wired: return "Wired"
        case .cellular: return "Cellular"
        case .other: return "Other connection"
        }
    }

    public var symbolName: String {
        guard isOnline else { return "wifi.slash" }
        return link == .wifi ? "wifi" : "network"
    }
}

public enum NetworkAddress {
    public struct Candidate: Equatable {
        public let interface: String
        public let address: String

        public init(interface: String, address: String) {
            self.interface = interface
            self.address = address
        }
    }

    private static let ignoredPrefixes = ["127.", "169.254."]

    public static func pick(from candidates: [Candidate], preferring interfaces: [String]) -> String? {
        let usable = candidates.filter { candidate in
            !ignoredPrefixes.contains { candidate.address.hasPrefix($0) }
        }
        for interface in interfaces {
            if let match = usable.first(where: { $0.interface == interface }) {
                return match.address
            }
        }
        return usable.first?.address
    }
}
