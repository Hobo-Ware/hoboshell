import AppKit
import HoboshellCore

struct TaskbarButtonModel {
    let slot: TaskbarSlot
    let name: String
    let icon: NSImage?
    let items: [TaskbarItem]
    let isActive: Bool
    let badge: String?
    let launch: (() -> Void)?
    let activateApp: (() -> Void)?
    let quit: (() -> Void)?

    var appID: String { slot.appID }
    var isGroup: Bool { items.count > 1 }
    var isIconOnly: Bool { items.isEmpty }
    var title: String { items.count == 1 ? items[0].title : name }

    var runState: DSRunMark.State {
        guard slot.isRunning else { return .none }
        return isActive ? .active : .running
    }

    var key: String {
        let titles = items.map { "\($0.title)|\($0.isActive)" }.joined(separator: ";")
        return "\(appID)#\(titles)#\(slot.isPinned)#\(slot.isRunning)#\(isActive)#\(badge ?? "")"
    }

    var revealWindow: (() -> Void)? {
        let target = items.first(where: \.isActive) ?? items.first
        return target?.reveal
    }
}

enum TaskbarButtonModels {
    static func make(slots: [TaskbarSlot], snapshot: TaskbarSnapshot) -> [TaskbarButtonModel] {
        let apps = Dictionary(snapshot.apps.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return slots.compactMap { slot in
            let items = slot.windows.map { snapshot.items[$0] }
            let badge = snapshot.badges[slot.appID]
            if let first = items.first {
                return TaskbarButtonModel(
                    slot: slot,
                    name: first.appName ?? first.title,
                    icon: first.icon,
                    items: items,
                    isActive: items.contains(where: \.isActive),
                    badge: badge,
                    launch: nil,
                    activateApp: nil,
                    quit: first.quit
                )
            }
            if let app = apps[slot.appID], slot.isRunning {
                return TaskbarButtonModel(
                    slot: slot,
                    name: app.name,
                    icon: app.icon,
                    items: [],
                    isActive: app.isActive,
                    badge: badge,
                    launch: nil,
                    activateApp: app.activate,
                    quit: app.quit
                )
            }
            guard let installed = InstalledApp(bundleIdentifier: slot.appID) else { return nil }
            return TaskbarButtonModel(
                slot: slot,
                name: installed.name,
                icon: installed.icon,
                items: [],
                isActive: false,
                badge: nil,
                launch: installed.launch,
                activateApp: nil,
                quit: nil
            )
        }
    }
}

private struct InstalledApp {
    let name: String
    let icon: NSImage
    let url: URL

    init?(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return nil }
        self.url = url
        name = url.deletingPathExtension().lastPathComponent
        icon = HoboIcon.image(forFile: url.path)
    }

    func launch() {
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
