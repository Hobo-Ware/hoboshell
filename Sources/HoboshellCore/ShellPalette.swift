import Foundation

public struct RGB: Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(white: Double) {
        self.init(red: white, green: white, blue: white)
    }

    public static let white = RGB(white: 1)
    public static let black = RGB(white: 0)

    public var relativeLuminance: Double {
        0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue)
    }

    public func blended(over backdrop: RGB, alpha: Double) -> RGB {
        RGB(
            red: red * alpha + backdrop.red * (1 - alpha),
            green: green * alpha + backdrop.green * (1 - alpha),
            blue: blue * alpha + backdrop.blue * (1 - alpha)
        )
    }

    private static func linear(_ value: Double) -> Double {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}

public enum Contrast {
    public static func ratio(_ first: RGB, _ second: RGB) -> Double {
        let lighter = max(first.relativeLuminance, second.relativeLuminance)
        let darker = min(first.relativeLuminance, second.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

public enum ShellPalette {
    public static let raisedSurface = RGB(white: 0.19)
    public static let text = RGB(white: 0.96)
    public static let dimText = RGB(white: 0.70)
    public static let accent = RGB(red: 0.27, green: 0.55, blue: 0.96)
    public static let accentFill = RGB(red: 0.16, green: 0.42, blue: 0.85)
    public static let onAccent = RGB.white
    public static let accentFillHover = accentFill.blended(over: .black, alpha: 0.9)
    public static let accentFillPressed = accentFill.blended(over: .black, alpha: 0.8)
    public static let flyoutTintAlpha = 0.94
    public static let glassSurface = RGB(white: 0.10)
    public static let glassTintAlpha = 0.85
    public static let disabledAlpha = 0.5
    public static let backdrops = [RGB.white, RGB.black]
    public static let barGlass = RGB(red: 24.0 / 255, green: 27.0 / 255, blue: 33.0 / 255)
    public static let barHairlineAlpha = 0.14
    public static let barRunLine = RGB(red: 163.0 / 255, green: 172.0 / 255, blue: 186.0 / 255)
    public static let barPlateHoverAlpha = 0.08
    public static let barPlatePressedAlpha = 0.05
    public static let barPlateFocusedAlpha = 0.12
    public static let barPlateFocusedHoverAlpha = 0.16
    public static let barPlateEdgeAlpha = 0.08

    public static func flyoutSurface(over backdrop: RGB) -> RGB {
        raisedSurface.blended(over: backdrop, alpha: flyoutTintAlpha)
    }

    public static func glassSurface(over backdrop: RGB) -> RGB {
        glassSurface.blended(over: backdrop, alpha: glassTintAlpha)
    }

    public static func disabled(_ color: RGB, over surface: RGB) -> RGB {
        color.blended(over: surface, alpha: disabledAlpha)
    }
}
