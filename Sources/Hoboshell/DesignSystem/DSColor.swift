import AppKit
import HoboshellCore

enum DSColor {
    static let surface = NSColor(white: 0.14, alpha: 1)
    static let raisedSurface = color(ShellPalette.raisedSurface)
    static let field = NSColor(white: 0.10, alpha: 1)
    static let border = NSColor.white.withAlphaComponent(0.16)
    static let text = color(ShellPalette.text)
    static let dimText = color(ShellPalette.dimText)
    static let accent = color(ShellPalette.accent)
    static let danger = NSColor(srgbRed: 0.95, green: 0.36, blue: 0.34, alpha: 1)
    static let faint = NSColor.white.withAlphaComponent(0.06)
    static let hover = NSColor.white.withAlphaComponent(0.12)
    static let pressed = NSColor.white.withAlphaComponent(0.20)
    static let selected = NSColor.white.withAlphaComponent(0.28)
    static let runMark = NSColor.white.withAlphaComponent(0.6)
    static let accentTint = accent.withAlphaComponent(0.22)
    static let onAccent = color(ShellPalette.onAccent)
    static let accentFill = color(ShellPalette.accentFill)
    static let accentFillHover = color(ShellPalette.accentFillHover)
    static let accentFillPressed = color(ShellPalette.accentFillPressed)
    static let focusRing = accent
    static let disabledAlpha = CGFloat(ShellPalette.disabledAlpha)
    static let flyoutTint = raisedSurface.withAlphaComponent(CGFloat(ShellPalette.flyoutTintAlpha))

    private static func color(_ rgb: RGB) -> NSColor {
        NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }

    static func desktop(for variant: ShellVariant) -> NSColor {
        switch variant {
        case .bottomTaskbar: return NSColor(calibratedRed: 0.0, green: 0.32, blue: 0.55, alpha: 1)
        case .topBarWithDock: return NSColor(calibratedRed: 0.27, green: 0.12, blue: 0.30, alpha: 1)
        }
    }
}
