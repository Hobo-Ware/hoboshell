import AppKit
import ApplicationServices
import HoboshellCore

final class DockBadges {
    private static let dockBundleID = "com.apple.dock"
    private static let statusLabelAttribute = "AXStatusLabel"
    private static let messagingTimeout: Float = 0.25
    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.badges", qos: .utility)

    func load(completion: @escaping ([String: String]) -> Void) {
        guard Accessibility.isTrusted else {
            completion([:])
            return
        }
        queue.async {
            let badges = Self.read()
            DispatchQueue.main.async {
                completion(badges)
            }
        }
    }

    private static func read() -> [String: String] {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: dockBundleID).first else { return [:] }
        let root = AXUIElementCreateApplication(dock.processIdentifier)
        AXUIElementSetMessagingTimeout(root, messagingTimeout)
        var badges: [String: String] = [:]
        for list in children(of: root) {
            for item in children(of: list) {
                guard let label = WindowCatalog.attribute(statusLabelAttribute, of: item) as? String,
                      let text = TaskbarBadgeText.display(label),
                      let url = WindowCatalog.attribute(kAXURLAttribute, of: item) as? URL,
                      let id = Bundle(url: url)?.bundleIdentifier else { continue }
                badges[id] = text
            }
        }
        return badges
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        WindowCatalog.attribute(kAXChildrenAttribute, of: element) as? [AXUIElement] ?? []
    }
}
