import AppKit

enum TraySettings {
    static let sound = "x-apple.systempreferences:com.apple.Sound-Settings.extension"
    static let network = "x-apple.systempreferences:com.apple.wifi-settings-extension"
    static let battery = "x-apple.systempreferences:com.apple.Battery-Settings.extension"
    static let dateAndTime = "x-apple.systempreferences:com.apple.Date-Time-Settings.extension"

    static func open(_ pane: String) {
        guard let url = URL(string: pane) else { return }
        NSWorkspace.shared.open(url)
    }

    static func button(title: String, pane: String, context: TrayFlyoutContext) -> DSButton {
        let button = DSButton(title: title, height: .regular, alignment: .leading)
        button.onPress = {
            context.dismiss()
            open(pane)
        }
        return button
    }
}
