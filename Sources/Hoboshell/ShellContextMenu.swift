import AppKit
import HoboshellCore

final class ShellContextMenu: NSMenu, NSMenuDelegate {
    struct GroupingChoice {
        let current: () -> TaskbarGrouping
        let choose: (TaskbarGrouping) -> Void
    }

    struct AlignmentChoice {
        let current: () -> TaskbarAlignment
        let choose: (TaskbarAlignment) -> Void
    }

    struct ToggleChoice {
        let title: String
        let isOn: () -> Bool
        let toggle: () -> Void
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
    private let versionItem = DSMenuItem(AppUpdater.shared.versionTitle, isEnabled: false) {}
    private let checkForUpdatesItem = DSMenuItem("Check for updates...") {
        AppUpdater.shared.checkForUpdates()
    }
    private let automaticUpdatesItem = DSMenuItem("Check for updates automatically") {
        AppUpdater.shared.checksAutomatically.toggle()
    }
    private var groupingItems: [(TaskbarGrouping, DSMenuItem)] = []
    private var groupingChoice: GroupingChoice?
    private var alignmentItems: [(TaskbarAlignment, DSMenuItem)] = []
    private var alignmentChoice: AlignmentChoice?
    private var toggles: [(ToggleChoice, DSMenuItem)] = []

    init(
        grouping: GroupingChoice? = nil,
        alignment: AlignmentChoice? = nil,
        toggles: [ToggleChoice] = []
    ) {
        super.init(title: "")
        DSMenu.style(self)
        groupingChoice = grouping
        alignmentChoice = alignment
        if let grouping {
            groupingItems = TaskbarGrouping.allCases.map { mode in
                (mode, DSMenuItem(mode.displayName) { grouping.choose(mode) })
            }
            addItem(DSMenu.submenu("Group windows", groupingItems.map(\.1)))
        }
        if let alignment {
            alignmentItems = TaskbarAlignment.allCases.map { mode in
                (mode, DSMenuItem(mode.displayName) { alignment.choose(mode) })
            }
            addItem(DSMenu.submenu("Taskbar alignment", alignmentItems.map(\.1)))
        }
        self.toggles = toggles.map { choice in
            (choice, DSMenuItem(choice.title) { choice.toggle() })
        }
        self.toggles.forEach { addItem($0.1) }
        addItem(commandTabItem)
        addItem(keepAboveBarItem)
        addItem(replaceDockItem)
        delegate = self
        addItem(DSMenu.separator())
        addItem(versionItem)
        addItem(checkForUpdatesItem)
        addItem(automaticUpdatesItem)
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
        checkForUpdatesItem.isEnabled = AppUpdater.shared.canCheckForUpdates
        automaticUpdatesItem.isEnabled = AppUpdater.shared.isRunning
        automaticUpdatesItem.state = AppUpdater.shared.checksAutomatically ? .on : .off
        for (choice, item) in toggles {
            item.state = choice.isOn() ? .on : .off
        }
        if let current = alignmentChoice?.current() {
            for (mode, item) in alignmentItems {
                item.state = mode == current ? .on : .off
            }
        }
        guard let current = groupingChoice?.current() else { return }
        for (mode, item) in groupingItems {
            item.state = mode == current ? .on : .off
        }
    }
}
