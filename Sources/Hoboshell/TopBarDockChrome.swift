import AppKit
import HoboshellCore

final class TopBarDockChrome: ShellChrome {
    var actions = ShellActions()

    private let topBar: TopBarPanel
    private let dock: SideDockPanel

    init(layout: ShellLayout, switchTitle: String) {
        var switchVariant: (() -> Void)?
        let makeMenu = { ShellContextMenu(switchTitle: switchTitle) { switchVariant?() } }
        topBar = TopBarPanel(frame: layout.bar, contextMenu: makeMenu())
        dock = SideDockPanel(frame: layout.dock ?? .zero, contextMenu: makeMenu())

        switchVariant = { [weak self] in self?.actions.onSwitchVariant?() }
        topBar.onOverview = { [weak self] in self?.actions.onStart?() }
        dock.onShowApps = { [weak self] in self?.actions.onStart?() }
        dock.onFiles = { [weak self] in self?.actions.onFiles?() }
    }

    func show() {
        topBar.orderFrontRegardless()
        dock.orderFrontRegardless()
    }

    func dismiss() {
        topBar.orderOut(nil)
        dock.orderOut(nil)
    }

    func update(items: [TaskbarItem]) {
        dock.update(items: items)
    }

    func reposition(to layout: ShellLayout) {
        topBar.setFrame(layout.bar, display: true)
        dock.setFrame(layout.dock ?? .zero, display: true)
    }

    func startMenuOrigin(menuSize: NSSize) -> NSPoint {
        NSPoint(x: dock.frame.maxX + 8, y: topBar.frame.minY - 8 - menuSize.height)
    }
}
