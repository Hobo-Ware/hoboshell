import AppKit
import HoboshellCore

final class ShellContextMenu: NSMenu, NSMenuDelegate {
    struct GroupingChoice {
        let current: () -> TaskbarGrouping
        let choose: (TaskbarGrouping) -> Void
    }

    private let replaceDockItem = DSMenuItem("Replace the Mac Dock and desktop icons") {
        SystemChrome.setWanted(!SystemChrome.isWanted)
    }
    private let keepAboveBarItem = DSMenuItem("Keep windows above the taskbar") {
        WindowNudger.setEnabled(!WindowNudger.isEnabled)
    }
    private let commandTabItem = DSMenuItem("Use Hoboshell for Command+Tab") {
        SwitcherSettings.setTakesCommandTab(!SwitcherSettings.takesCommandTab)
    }
    private var groupingItems: [(TaskbarGrouping, DSMenuItem)] = []
    private var groupingChoice: GroupingChoice?

    private let iconPackItems: [(IconPack, NSMenuItem)] = IconPack.allCases.map { pack in
        (pack, DSMenuItem(pack.title) { IconPack.current = pack })
    }

    init(switchTitle: String, grouping: GroupingChoice? = nil, onSwitchVariant: @escaping () -> Void) {
        super.init(title: "")
        DSMenu.style(self)
        groupingChoice = grouping
        addItem(DSMenuItem(switchTitle, handler: onSwitchVariant))
        if let grouping {
            groupingItems = TaskbarGrouping.allCases.map { mode in
                (mode, DSMenuItem(mode.displayName) { grouping.choose(mode) })
            }
            addItem(DSMenu.submenu("Group windows", groupingItems.map(\.1)))
        }
        addItem(DSMenu.submenu("Folder style", iconPackItems.map(\.1)))
        addItem(commandTabItem)
        addItem(keepAboveBarItem)
        addItem(replaceDockItem)
        delegate = self
        addItem(DSMenu.separator())
        addItem(DSMenuItem("Quit Hoboshell") {
            NSApp.terminate(nil)
        })
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        replaceDockItem.state = SystemChrome.isWanted ? .on : .off
        keepAboveBarItem.state = WindowNudger.isEnabled ? .on : .off
        commandTabItem.state = SwitcherSettings.takesCommandTab ? .on : .off
        for (pack, item) in iconPackItems {
            item.state = pack == IconPack.current ? .on : .off
        }
        guard let current = groupingChoice?.current() else { return }
        for (mode, item) in groupingItems {
            item.state = mode == current ? .on : .off
        }
    }
}
