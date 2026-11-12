public struct BatteryDetails: Equatable {
    public let status: BatteryStatus
    public let isOnACPower: Bool
    public let isFullyCharged: Bool
    public let minutes: Int?

    public init(status: BatteryStatus, isOnACPower: Bool, isFullyCharged: Bool, minutes: Int?) {
        self.status = status
        self.isOnACPower = isOnACPower
        self.isFullyCharged = isFullyCharged
        self.minutes = minutes
    }

    public var stateText: String {
        if isFullyCharged { return "Fully charged" }
        if status.isCharging { return "Charging" }
        return isOnACPower ? "Plugged in, not charging" : "On battery"
    }

    public var timeText: String? {
        guard let minutes, minutes > 0, !isFullyCharged else { return nil }
        if status.isCharging { return "\(Self.durationText(minutes: minutes)) until full" }
        return isOnACPower ? nil : "\(Self.durationText(minutes: minutes)) remaining"
    }

    public static func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    public static func lowPowerModeText(isOn: Bool) -> String {
        "Low Power Mode: \(isOn ? "On" : "Off")"
    }
}
