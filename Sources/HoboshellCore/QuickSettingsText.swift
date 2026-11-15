public enum QuickSettingsText {
    public static func wifiLabel(isPoweredOn: Bool, isConnected: Bool, name: String?) -> String {
        guard isPoweredOn else { return "Off" }
        guard isConnected else { return "Not connected" }
        guard let name, !name.isEmpty else { return "Connected" }
        return name
    }

    public static func switchLabel(isOn: Bool) -> String {
        isOn ? "On" : "Off"
    }

    public static func appearanceLabel(isDark: Bool) -> String {
        isDark ? "Dark" : "Light"
    }
}
