import CoreGraphics

public enum StartMenuPlacement {
    public static func originX(
        alignment: TaskbarAlignment,
        bar: CGRect,
        menuWidth: CGFloat,
        inset: CGFloat
    ) -> CGFloat {
        let leftmost = bar.minX + inset
        guard alignment == .centred else { return leftmost }
        let centred = (bar.midX - menuWidth / 2).rounded()
        let rightmost = bar.maxX - inset - menuWidth
        return max(min(centred, rightmost), leftmost)
    }
}
