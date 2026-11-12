import AppKit

enum DSPanelStyle {
    enum Kind {
        case bar
        case opaqueBar
        case flyout
    }

    static let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

    @discardableResult
    static func apply(to panel: NSPanel, kind: Kind, level: NSWindow.Level = .statusBar) -> DSCard {
        // Turning a panel into a floating panel resets its level, so the level is set after it.
        panel.isFloatingPanel = true
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovable = false
        panel.hasShadow = kind == .flyout
        panel.isOpaque = false
        panel.backgroundColor = .clear

        let card = kind == .flyout
            ? DSCard(radius: DSRadius.card)
            : DSCard(radius: DSRadius.none, isBordered: false)
        if kind == .opaqueBar {
            let fill = NSView()
            fill.wantsLayer = true
            fill.layer?.backgroundColor = DSColor.surface.cgColor
            pin(fill, to: card)
        }
        panel.contentView = card
        return card
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
