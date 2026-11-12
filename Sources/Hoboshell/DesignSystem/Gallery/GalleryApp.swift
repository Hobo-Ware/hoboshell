import AppKit

final class GalleryApp: NSObject, NSApplicationDelegate {
    private var window: GalleryWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainMenu.install()
        let window = GalleryWindow()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
