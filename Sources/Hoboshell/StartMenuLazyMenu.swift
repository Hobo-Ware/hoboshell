import AppKit

final class StartMenuLazyMenu: NSMenu, NSMenuDelegate {
    private let build: () -> [NSMenuItem]

    init(_ build: @escaping () -> [NSMenuItem]) {
        self.build = build
        super.init(title: "")
        DSMenu.style(self)
        delegate = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        build().forEach(menu.addItem)
    }
}
