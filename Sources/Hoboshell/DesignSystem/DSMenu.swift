import AppKit

enum DSMenu {
    static func make(_ items: [NSMenuItem], title: String = "") -> NSMenu {
        let menu = NSMenu(title: title)
        style(menu)
        for item in items {
            menu.addItem(item)
        }
        return menu
    }

    static func style(_ menu: NSMenu) {
        menu.autoenablesItems = false
        menu.appearance = NSAppearance(named: .darkAqua)
    }

    static func separator() -> NSMenuItem {
        .separator()
    }

    static func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = make(items, title: title)
        return item
    }

    static func popUp(_ menu: NSMenu, below view: NSView) {
        menu.popUp(positioning: nil, at: .zero, in: view)
    }
}
