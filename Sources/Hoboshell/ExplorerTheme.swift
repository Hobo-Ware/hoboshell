import AppKit

enum ExplorerTheme {
    static let toolbarHeight: CGFloat = 44
    static let commandBarHeight: CGFloat = 36
    static let statusBarHeight: CGFloat = 24
    static let buttonHeight: CGFloat = 28
    static let iconButtonWidth: CGFloat = 32
    static let sidebarWidth: CGFloat = 190
    static let background = NSColor(white: 0.14, alpha: 1)
    static let fieldBackground = NSColor.white.withAlphaComponent(0.08).cgColor
    static let fieldBorder = NSColor.white.withAlphaComponent(0.16).cgColor
    static let selectionBackground = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
    static let disabledAlpha: CGFloat = 0.35

    static func symbol(_ name: String, side: CGFloat = 16) -> NSImage? {
        ShellButton.icon(NSImage(systemSymbolName: name, accessibilityDescription: nil), side: side)
    }

    static func button(
        symbol name: String,
        title: String = "",
        tip: String,
        width: CGFloat = iconButtonWidth,
        target: AnyObject,
        action: Selector
    ) -> HoverButton {
        let button = ShellButton.make(
            title: title,
            image: symbol(name),
            size: NSSize(width: width, height: buttonHeight),
            fontSize: 12,
            target: target,
            action: action
        )
        button.toolTip = tip
        return button
    }

    static func setEnabled(_ button: HoverButton, _ enabled: Bool) {
        button.isEnabled = enabled
        button.alphaValue = enabled ? 1 : disabledAlpha
        if enabled {
            button.updateTrackingAreas()
        } else {
            button.trackingAreas.forEach(button.removeTrackingArea)
        }
    }

    static func separator() -> NSBox {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }
}
