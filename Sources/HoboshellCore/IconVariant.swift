import CoreGraphics

public enum IconVariant {
    public static let smallestSide: CGFloat = 24
    public static let smallSuffix = "-sm"

    public static func candidates(name: String, side: CGFloat) -> [String] {
        side <= smallestSide ? [name + smallSuffix, name] : [name]
    }
}
