import AppKit
import HoboshellCore

enum DSBarColor {
    static let glass = color(ShellPalette.barGlass, alpha: ShellPalette.barGlassAlpha)
    static let solid = color(ShellPalette.barGlass, alpha: SolidSurfaceLook.alpha)
    static let hairline = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barHairlineAlpha))
    static let runLine = color(ShellPalette.barRunLine)
    static let plateHover = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barPlateHoverAlpha))
    static let platePressed = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barPlatePressedAlpha))
    static let plateFocused = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barPlateFocusedAlpha))
    static let plateFocusedHover = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barPlateFocusedHoverAlpha))
    static let plateEdge = NSColor.white.withAlphaComponent(CGFloat(ShellPalette.barPlateEdgeAlpha))
    static let stackedNear = NSColor.white.withAlphaComponent(0.10)
    static let stackedFar = NSColor.white.withAlphaComponent(0.05)

    private static func color(_ rgb: RGB, alpha: Double = 1) -> NSColor {
        NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: CGFloat(alpha))
    }
}
