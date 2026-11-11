import AppKit
import HoboshellCore

final class ShellContextMenu: NSMenu, NSMenuDelegate {
    struct GroupingChoice {
        let current: () -> TaskbarGrouping
        let choose: (TaskbarGrouping) -> Void
    }

    private let hideSystemUIItem = DSMenuItem("Hide the Mac Dock and desktop icons") {
        SystemChrome.setWanted(!SystemChrome.isWanted)
    }
    private var groupingItems: [(TaskbarGrouping, DSMenuItem)] = []
    private var groupingChoice: GroupingChoice?

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
        addItem(hideSystemUIItem)
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
        hideSystemUIItem.state = SystemChrome.isWanted ? .on : .off
        guard let current = groupingChoice?.current() else { return }
        for (mode, item) in groupingItems {
            item.state = mode == current ? .on : .off
        }
    }
}
