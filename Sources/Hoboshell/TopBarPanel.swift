import AppKit

final class TopBarPanel: NSPanel {
    private static let overviewButtonSize = NSSize(width: 86, height: 22)

    var onOverview: (() -> Void)?

    init(frame: NSRect, contextMenu: NSMenu) {
        super.init(contentRect: frame, styleMask: ShellPanelStyle.styleMask, backing: .buffered, defer: false)
        let background = ShellPanelStyle.apply(to: self)

        let overviewButton = ShellButton.make(
            title: "Activities",
            size: Self.overviewButtonSize,
            fontSize: 12,
            target: self,
            action: #selector(overviewPressed)
        )
        overviewButton.toolTip = "Search apps"

        let root = NSStackView()
        root.orientation = .horizontal
        root.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 12)
        root.addView(overviewButton, in: .leading)
        root.addView(SystemTrayView(clockOnOneLine: true, height: .compact), in: .trailing)
        ShellPanelStyle.pin(root, to: background)
        background.menu = contextMenu
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    @objc private func overviewPressed() {
        onOverview?()
    }
}
