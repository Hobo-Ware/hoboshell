import CoreGraphics

public enum TrayFlyoutPlacement {
    public static func origin(size: CGSize, anchor: CGRect, screen: CGRect, gap: CGFloat, margin: CGFloat) -> CGPoint {
        let centred = anchor.midX - size.width / 2
        let furthestRight = screen.maxX - margin - size.width
        let x = max(screen.minX + margin, min(centred, furthestRight))
        let above = anchor.maxY + gap
        let fitsAbove = above + size.height <= screen.maxY - margin
        let y = fitsAbove ? above : max(screen.minY + margin, anchor.minY - gap - size.height)
        return CGPoint(x: x.rounded(), y: y.rounded())
    }
}
