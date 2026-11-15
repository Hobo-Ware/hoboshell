public struct BatteryIcon: Equatable {
    public static let criticalBelowPercent = 6

    public let symbolName: String
    public let tone: TrayTone

    public init(status: BatteryStatus, isLowPowerMode: Bool) {
        symbolName = status.symbolName
        if status.isCharging {
            tone = .good
        } else if status.percent < Self.criticalBelowPercent {
            tone = .critical
        } else if isLowPowerMode {
            tone = .warning
        } else {
            tone = .normal
        }
    }
}
