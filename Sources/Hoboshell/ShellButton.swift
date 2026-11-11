import AppKit

enum ShellButton {
    static let activeBackground = NSColor.white.withAlphaComponent(0.22).cgColor
    static let hoverBackground = NSColor.white.withAlphaComponent(0.12).cgColor

    static func make(
        title: String = "",
        image: NSImage? = nil,
        size: NSSize,
        fontSize: CGFloat = 18,
        target: AnyObject,
        action: Selector
    ) -> HoverButton {
        let button = HoverButton(title: title, target: target, action: action)
        let isLabelled = image != nil && !title.isEmpty
        button.image = image
        button.imagePosition = image == nil ? .noImage : (isLabelled ? .imageLeading : .imageOnly)
        button.alignment = isLabelled ? .left : .center
        button.cell?.lineBreakMode = .byTruncatingTail
        button.isBordered = false
        button.font = .systemFont(ofSize: fontSize)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size.width),
            button.heightAnchor.constraint(equalToConstant: size.height),
        ])
        return button
    }

    static func icon(_ image: NSImage?, side: CGFloat) -> NSImage? {
        let resized = image?.copy() as? NSImage
        resized?.size = NSSize(width: side, height: side)
        return resized
    }
}
