import AppKit
import HoboshellCore

struct StartMenuItem {
    let view: DSControl
    let activate: () -> Void
}

struct StartMenuGroup {
    let items: [StartMenuItem]
    let columns: Int
}

struct StartMenuPage {
    let view: NSView
    let groups: [StartMenuGroup]
    let entrySection: Int

    static let empty = StartMenuPage(view: NSView(), groups: [], entrySection: 0)

    var sections: [StartSection] {
        groups.map { StartSection(count: $0.items.count, columns: $0.columns) }
    }

    var hasItems: Bool {
        groups.contains { !$0.items.isEmpty }
    }

    var entry: StartPosition? {
        StartNavigation.first(in: sections, from: entrySection) ?? StartNavigation.first(in: sections)
    }

    func item(at position: StartPosition) -> StartMenuItem? {
        guard groups.indices.contains(position.section), groups[position.section].items.indices.contains(position.index) else {
            return nil
        }
        return groups[position.section].items[position.index]
    }
}

struct StartMenuActions {
    var open: (StartMenuApp) -> Void
    var openFile: (URL) -> Void
    var openSetting: (StartSettingsPane) -> Void
    var showAllApps: () -> Void
    var showPinned: () -> Void
    var appMenu: (StartMenuApp) -> NSMenu
    var fileMenu: (URL) -> NSMenu
    var movePin: (String, String?) -> Void
}
