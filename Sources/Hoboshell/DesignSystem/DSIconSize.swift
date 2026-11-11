import AppKit

enum DSIconSize {
    static let inline: CGFloat = 16
    static let toolbar: CGFloat = 20
    static let taskbar: CGFloat = 24
    static let grid: CGFloat = 48

    static func symbol(_ name: String, description: String? = nil) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: description)
    }
}
