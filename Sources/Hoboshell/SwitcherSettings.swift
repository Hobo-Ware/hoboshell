import Foundation

enum SwitcherSettings {
    static let didChange = Notification.Name("dev.hoboware.hoboshell.switcherSettingDidChange")
    private static let commandTabKey = "SwitcherTakesCommandTab"

    static var takesCommandTab: Bool {
        UserDefaults.standard.object(forKey: commandTabKey) as? Bool ?? true
    }

    static func setTakesCommandTab(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: commandTabKey)
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}
