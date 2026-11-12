import CoreGraphics

public enum WindowNudge {
    public static let minimumHeight: CGFloat = 120
    private static let screenSlack: CGFloat = 1

    public static func frame(for window: CGRect, bar: CGRect, screen: CGRect) -> CGRect? {
        guard screen.insetBy(dx: -screenSlack, dy: -screenSlack).contains(bar),
              window.height < screen.height,
              window.maxX > bar.minX, window.minX < bar.maxX,
              window.minY < bar.maxY else { return nil }
        let height = window.maxY - bar.maxY
        guard height >= minimumHeight else { return nil }
        return CGRect(x: window.minX, y: bar.maxY, width: window.width, height: height)
    }

    public static func flipped(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryScreenHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}
