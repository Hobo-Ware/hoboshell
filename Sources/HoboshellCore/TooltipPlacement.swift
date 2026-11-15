import CoreGraphics

public enum TooltipPlacement {
    public static func origin(size: CGSize, anchor: CGRect, screen: CGRect, gap: CGFloat, margin: CGFloat) -> CGPoint {
        let furthestRight = screen.maxX - margin - size.width
        let x = max(screen.minX + margin, min(anchor.midX - size.width / 2, furthestRight))

        let above = anchor.maxY + gap
        let below = anchor.minY - gap - size.height
        let fitsAbove = above + size.height <= screen.maxY - margin
        let fitsBelow = below >= screen.minY + margin
        let prefersBelow = anchor.midY > screen.midY
        let y: CGFloat
        switch (prefersBelow, fitsAbove, fitsBelow) {
        case (true, _, true), (false, false, true): y = below
        case (false, true, _), (true, true, false): y = above
        default: y = max(screen.minY + margin, min(above, screen.maxY - margin - size.height))
        }
        return CGPoint(x: x.rounded(), y: y.rounded())
    }
}
