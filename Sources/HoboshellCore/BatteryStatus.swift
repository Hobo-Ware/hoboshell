public struct BatteryStatus: Equatable {
    public let percent: Int
    public let isCharging: Bool

    public init(percent: Int, isCharging: Bool) {
        self.percent = min(max(percent, 0), 100)
        self.isCharging = isCharging
    }

    public var label: String { "\(percent)%" }

    public var symbolName: String {
        if isCharging {
            return "battery.100.bolt"
        }
        switch percent {
        case ..<13: return "battery.0"
        case ..<38: return "battery.25"
        case ..<63: return "battery.50"
        case ..<88: return "battery.75"
        default: return "battery.100"
        }
    }
}
