import Foundation

public struct StartSettingsPane: Equatable {
    public let name: String
    public let address: String
    public let keywords: [String]

    public init(name: String, address: String, keywords: [String] = []) {
        self.name = name
        self.address = address
        self.keywords = keywords
    }
}

public enum StartSettingsPanes {
    private static let prefix = "x-apple.systempreferences:"

    public static let all: [StartSettingsPane] = [
        pane("Wi-Fi", "com.apple.wifi-settings-extension", "wireless", "internet"),
        pane("Bluetooth", "com.apple.BluetoothSettings", "wireless", "headphones"),
        pane("Network", "com.apple.Network-Settings.extension", "ethernet", "vpn", "dns", "internet"),
        pane("Notifications", "com.apple.Notifications-Settings.extension", "alerts", "banners"),
        pane("Sound", "com.apple.Sound-Settings.extension", "volume", "audio", "output", "input"),
        pane("Focus", "com.apple.Focus-Settings.extension", "do not disturb"),
        pane("Screen Time", "com.apple.Screen-Time-Settings.extension", "limits", "usage"),
        pane("General", "com.apple.systempreferences.GeneralSettings", "about", "storage", "language"),
        pane("Appearance", "com.apple.Appearance-Settings.extension", "dark mode", "theme", "accent"),
        pane("Accessibility", "com.apple.Accessibility-Settings.extension", "zoom", "voiceover", "contrast"),
        pane("Control Center", "com.apple.ControlCenter-Settings.extension", "menu bar"),
        pane("Siri & Spotlight", "com.apple.Siri-Settings.extension", "search", "assistant"),
        pane("Privacy & Security", "com.apple.settings.PrivacySecurity.extension", "permissions", "firewall", "filevault"),
        pane("Desktop & Dock", "com.apple.Desktop-Settings.extension", "dock", "mission control", "hot corners"),
        pane("Displays", "com.apple.Displays-Settings.extension", "monitor", "resolution", "brightness", "night shift"),
        pane("Wallpaper", "com.apple.Wallpaper-Settings.extension", "background", "screen saver"),
        pane("Battery", "com.apple.Battery-Settings.extension", "power", "energy"),
        pane("Lock Screen", "com.apple.Lock-Screen-Settings.extension", "password", "screen saver"),
        pane("Touch ID & Password", "com.apple.Touch-ID-Settings.extension", "fingerprint", "login"),
        pane("Users & Groups", "com.apple.Users-Groups-Settings.extension", "accounts", "login"),
        pane("Passwords", "com.apple.Passwords-Settings.extension", "keychain"),
        pane("Internet Accounts", "com.apple.Internet-Accounts-Settings.extension", "email", "mail"),
        pane("Keyboard", "com.apple.Keyboard-Settings.extension", "shortcuts", "input sources", "dictation"),
        pane("Mouse", "com.apple.Mouse-Settings.extension", "pointer", "scrolling"),
        pane("Trackpad", "com.apple.Trackpad-Settings.extension", "gestures", "tap to click"),
        pane("Printers & Scanners", "com.apple.Print-Scan-Settings.extension", "printer"),
        pane("Software Update", "com.apple.Software-Update-Settings.extension", "upgrade", "macos"),
        pane("Sharing", "com.apple.Sharing-Settings.extension", "airdrop", "file sharing", "remote login", "hostname"),
        pane("Date & Time", "com.apple.Date-Time-Settings.extension", "clock", "time zone"),
        pane("Storage", "com.apple.settings.Storage", "disk", "space"),
        pane("Apple ID", "com.apple.systempreferences.AppleIDSettings", "icloud", "account"),
    ]

    public static func matches(query: String, in panes: [StartSettingsPane] = all) -> [StartSettingsPane] {
        let ranked = StartNameMatch.rank(query: query, in: panes.map(\.name)).map { panes[$0] }
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return ranked }
        let byKeyword = panes.filter { pane in
            !ranked.contains(pane) && !StartNameMatch.rank(query: query, in: pane.keywords).isEmpty
        }
        return ranked + byKeyword
    }

    private static func pane(_ name: String, _ identifier: String, _ keywords: String...) -> StartSettingsPane {
        StartSettingsPane(name: name, address: prefix + identifier, keywords: keywords)
    }
}
