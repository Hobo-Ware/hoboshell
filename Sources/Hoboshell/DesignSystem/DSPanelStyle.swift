import AppKit

enum DSPanelStyle {
    enum Kind {
        case bar
        case flyout
    }

    static let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

    @discardableResult
    static func apply(to panel: NSPanel, kind: Kind, level: NSWindow.Level = .statusBar) -> DSCard {
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovable = false
        panel.hasShadow = kind == .flyout
        panel.isOpaque = false
        panel.backgroundColor = .clear

        let card = kind == .bar
            ? DSCard(radius: DSRadius.none, isBordered: false)
            : DSCard(radius: DSRadius.card)
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
