import AppKit

enum DSIconSize {
    static let inline: CGFloat = 16
    static let toolbar: CGFloat = 20
    static let taskbar: CGFloat = 24
    static let startLogo: CGFloat = 32
    static let grid: CGFloat = 48
    static let picture: CGFloat = 96

    static func fit(_ image: NSImage?, side: CGFloat) -> NSImage? {
        let resized = image?.copy() as? NSImage
        resized?.size = NSSize(width: side, height: side)
        return resized
    }

    static func symbol(_ name: String, description: String? = nil) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: description)
    }
}
