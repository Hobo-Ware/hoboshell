import AppKit

enum TrayAppMenu {
    static func make(for app: TrayApp, afterAction: @escaping () -> Void = {}) -> NSMenu {
        DSMenu.make([
            DSMenuItem("Open") {
                afterAction()
                app.open()
            },
            DSMenuItem("Quit \(app.name)") {
                afterAction()
                app.quit()
            },
        ])
    }
}
