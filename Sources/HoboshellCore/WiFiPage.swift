public enum WiFiConnection: Equatable {
    case off
    case notConnected
    case connected(name: String?)

    public static func resolve(isPoweredOn: Bool, ssid: String?, hasLink: Bool) -> WiFiConnection {
        guard isPoweredOn else { return .off }
        guard ssid != nil || hasLink else { return .notConnected }
        return .connected(name: ssid)
    }

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var name: String? {
        if case .connected(let name) = self, let name, !name.isEmpty { return name }
        return nil
    }
}

public struct WiFiCurrentNetwork: Equatable {
    public let name: String?
    public let bars: Int
    public let isSecured: Bool?

    public var statusText: String {
        switch isSecured {
        case true?: return "Connected, secured"
        case false?: return "Connected, open"
        case nil: return "Connected"
        }
    }
}

public struct WiFiNetworksPage: Equatable {
    public enum Progress: Equatable {
        case scanning
        case nothingFound
        case listed
    }

    public let current: WiFiCurrentNetwork?
    public let others: [WiFiNetwork]
    public let progress: Progress

    public var othersTitle: String {
        current?.name == nil ? "Networks nearby" : "Other networks"
    }
}

public enum WiFiPage: Equatable {
    case unavailable
    case off
    case namesHidden(isConnected: Bool)
    case networks(WiFiNetworksPage)

    public static func make(
        isAvailable: Bool,
        connection: WiFiConnection,
        namesAllowed: Bool,
        isScanning: Bool,
        rssi: Int,
        scanned: [WiFiScanResult]
    ) -> WiFiPage {
        guard isAvailable else { return .unavailable }
        guard connection != .off else { return .off }
        guard namesAllowed else { return .namesHidden(isConnected: connection.isConnected) }
        let others = WiFiNetworks.others(from: scanned, excluding: connection.name)
        let current = connection.isConnected
            ? WiFiCurrentNetwork(
                name: connection.name,
                bars: WiFiSignal.bars(rssi: rssi),
                isSecured: connection.name.flatMap { name in scanned.first { $0.name == name }?.isSecured }
            )
            : nil
        let progress: WiFiNetworksPage.Progress = !others.isEmpty ? .listed : (isScanning ? .scanning : .nothingFound)
        return .networks(WiFiNetworksPage(current: current, others: others, progress: progress))
    }
}
