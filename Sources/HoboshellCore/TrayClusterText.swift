public enum TrayClusterText {
    public static func volume(level: Float, isMuted: Bool) -> String {
        isMuted ? "Volume muted" : "Volume \(TrayVolume.percentText(level))"
    }

    public static func battery(_ status: BatteryStatus) -> String {
        status.isCharging ? "Battery \(status.label), charging" : "Battery \(status.label)"
    }

    public static func tooltip(network: String, volume: String?, battery: String?) -> String {
        [network, volume, battery].compactMap { $0 }.joined(separator: ", ")
    }
}
