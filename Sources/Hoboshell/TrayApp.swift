import AppKit

struct TrayApp {
    let id: String
    let name: String
    let icon: NSImage?
    let iconPath: String?
    let badge: String?
    let open: () -> Void
    let quit: () -> Void

    init(
        id: String,
        name: String,
        icon: NSImage? = nil,
        iconPath: String? = nil,
        badge: String?,
        open: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.iconPath = iconPath
        self.badge = badge
        self.open = open
        self.quit = quit
    }

    var resolvedIcon: NSImage? {
        icon ?? AppIcons.shared.image(forPath: iconPath)
    }

    init(running app: NSRunningApplication, id: String, badge: String?) {
        self.init(
            id: id,
            name: app.localizedName ?? "",
            iconPath: app.bundleURL?.path,
            badge: badge,
            open: { Self.bringBack(app) },
            quit: { app.terminate() }
        )
    }

    private static func bringBack(_ app: NSRunningApplication) {
        app.unhide()
        guard let url = app.bundleURL else {
            app.activate()
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
