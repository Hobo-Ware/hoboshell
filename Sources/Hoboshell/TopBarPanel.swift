import AppKit

final class TopBarPanel: NSPanel {
    var onOverview: (() -> Void)?

    init(frame: NSRect, contextMenu: NSMenu) {
        super.init(contentRect: frame, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        let background = DSPanelStyle.apply(to: self, kind: .bar)

        let overviewButton = DSButton(title: "Activities", height: .compact, tip: "Search apps")
        overviewButton.onPress = { [weak self] in
            self?.onOverview?()
        }

        let root = NSStackView()
        root.orientation = .horizontal
        root.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: DSSpacing.s)
        root.addView(overviewButton, in: .leading)
        root.addView(SystemTrayView(clockOnOneLine: true, height: .compact), in: .trailing)
        DSPanelStyle.pin(root, to: background)
        background.menu = contextMenu
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
