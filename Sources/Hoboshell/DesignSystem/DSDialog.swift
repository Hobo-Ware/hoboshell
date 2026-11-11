import AppKit

enum DSDialog {
    static func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.window.appearance = NSAppearance(named: .darkAqua)
        alert.runModal()
    }

    static func showError(title: String, message: String) {
        let alert = makeAlert(title: title, message: message, style: .warning)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func confirm(title: String, message: String, confirmTitle: String, isDestructive: Bool = false) -> Bool {
        let alert = makeAlert(title: title, message: message, style: isDestructive ? .critical : .informational)
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "Cancel")
        alert.buttons[0].hasDestructiveAction = isDestructive
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func makeAlert(title: String, message: String, style: NSAlert.Style) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.window.appearance = NSAppearance(named: .darkAqua)
        return alert
    }
}
