import AppKit

final class AppIcons {
    struct Installed {
        let name: String
        let url: URL
        let icon: NSImage
    }

    static let shared = AppIcons()
    static let didLoad = Notification.Name("HoboshellAppIconsDidLoad")

    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.icons", qos: .userInitiated)
    private var images: [String: NSImage] = [:]
    private var installed: [String: Installed] = [:]
    private var missing = Set<String>()
    private var inFlight = Set<String>()

    func image(forPath path: String?) -> NSImage? {
        guard let path else { return nil }
        if let image = images[path] {
            return image
        }
        load(key: "file:\(path)") {
            let image = HoboIcon.image(forFile: path)
            DispatchQueue.main.async { self.images[path] = image }
        }
        return nil
    }

    func installedApp(_ bundleID: String) -> Installed? {
        if let app = installed[bundleID] {
            return app
        }
        guard !missing.contains(bundleID) else { return nil }
        load(key: "app:\(bundleID)") {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                DispatchQueue.main.async { self.missing.insert(bundleID) }
                return
            }
            let app = Installed(
                name: url.deletingPathExtension().lastPathComponent,
                url: url,
                icon: HoboIcon.image(forFile: url.path)
            )
            DispatchQueue.main.async { self.installed[bundleID] = app }
        }
        return nil
    }

    func warm(paths: [String]) {
        paths.forEach { _ = image(forPath: $0) }
    }

    func launch(bundleID: String) {
        queue.async {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func load(key: String, work: @escaping () -> Void) {
        guard inFlight.insert(key).inserted else { return }
        queue.async {
            work()
            DispatchQueue.main.async {
                self.inFlight.remove(key)
                NotificationCenter.default.post(name: Self.didLoad, object: self)
            }
        }
    }
}
