import AppKit
import ApplicationServices
import HoboshellCore

final class DockBadges {
    private static let dockBundleID = "com.apple.dock"
    private static let statusLabelAttribute = "AXStatusLabel"
    private static let pollInterval: TimeInterval = 1
    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.badges", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastPosted: [String: String]?

    func start() {
        guard timer == nil else { return }
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: Self.pollInterval, leeway: .milliseconds(100))
        source.setEventHandler { [weak self] in
            self?.poll()
        }
        source.resume()
        timer = source
    }

    private func poll() {
        guard Accessibility.isTrusted else { return }
        let observedAt = ShellClock.now()
        let badges = Self.read()
        guard badges != lastPosted else { return }
        lastPosted = badges
        ShellStore.post(.badgesRead(badges), observedAt: observedAt)
    }

    private static func read() -> [String: String] {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: dockBundleID).first else { return [:] }
        let root = AXUIElementCreateApplication(dock.processIdentifier)
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
