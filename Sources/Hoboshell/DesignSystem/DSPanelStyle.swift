import AppKit

enum DSPanelStyle {
    enum Kind {
        case bar
        case flyout
    }

    static let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

    @discardableResult
    static func apply(to panel: NSPanel, kind: Kind, level: NSWindow.Level = .statusBar) -> DSCard {
        configure(panel, kind: kind, level: level)
        let card = kind == .flyout
            ? DSCard(radius: DSRadius.card)
            : DSCard(radius: DSRadius.none, isBordered: false, isTinted: false)
        panel.contentView = card
        return card
    }

    static func applyGlassFlyout(to panel: NSPanel) -> NSView {
        configure(panel, kind: .flyout, level: .statusBar)
        let card = DSGlassCard()
        panel.contentView = card
        return card
    }

    @discardableResult
    static func applyGlassBar(to panel: NSPanel) -> NSView {
        configure(panel, kind: .bar, level: .statusBar)
        let content = NSView()
        panel.contentView = content
        return content
    }

    private static func configure(_ panel: NSPanel, kind: Kind, level: NSWindow.Level) {
        // Turning a panel into a floating panel resets its level, so the level is set after it.
        panel.isFloatingPanel = true
        panel.level = level
        panel.collectionBehavior = kind == .bar
            ? [.canJoinAllSpaces, .ignoresCycle]
            : [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovable = false
        panel.hasShadow = kind == .flyout
        panel.isOpaque = false
        panel.backgroundColor = .clear
    }

    static func pin(_ view: NSView, to container: NSView, inset: CGFloat = 0) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset),
        ])
    }
}
