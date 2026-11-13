import CoreGraphics

public enum PreviewCardLayout {
    public static func origin(cardSize: CGSize, anchor: CGRect, screen: CGRect, gap: CGFloat, margin: CGFloat) -> CGPoint {
        let centred = anchor.midX - cardSize.width / 2
        let furthestRight = screen.maxX - margin - cardSize.width
        let x = max(screen.minX + margin, min(centred, furthestRight))
        return CGPoint(x: x.rounded(), y: anchor.maxY + gap)
    }

    public static func fit(_ size: CGSize, within limit: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return limit }
        let scale = min(limit.width / size.width, limit.height / size.height, 1)
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }
}
