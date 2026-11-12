import AppKit

final class TrayAppsStore {
    static let shared = TrayAppsStore()
    static let didChange = Notification.Name("HoboshellTrayAppsDidChange")

    private static let sampleApps = [
        ("Messages", "/System/Applications/Messages.app", "3"),
        ("Mail", "/System/Applications/Mail.app", "12"),
        ("Notes", "/System/Applications/Notes.app", nil),
    ]

    private(set) var apps: [TrayApp] = []
    var showsSamples = false {
        didSet { NotificationCenter.default.post(name: Self.didChange, object: self) }
    }

    var flyoutApps: [TrayApp] {
        apps.isEmpty && showsSamples ? Self.samples : apps
    }

    private static var samples: [TrayApp] {
        sampleApps.map { name, path, badge in
            TrayApp(
                id: "sample:\(name)",
                name: "\(name) (sample)",
                icon: HoboIcon.image(forFile: path),
                badge: badge,
                open: {},
                quit: {}
            )
        }
    }

    func update(_ next: [TrayApp]) {
        guard next.map(\.signature) != apps.map(\.signature) else { return }
        apps = next
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}

private extension TrayApp {
    var signature: String {
        "\(id)|\(badge ?? "")"
    }
}
