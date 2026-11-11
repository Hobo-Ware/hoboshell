import CoreGraphics

public enum SnapRegion: Int {
    case leftHalf
    case rightHalf
    case maximize
}

public enum SnapGeometry {
    public static func accessibilityFrame(
        for region: SnapRegion,
        visibleFrame: CGRect,
        screenFrame: CGRect,
        primaryScreenHeight: CGFloat,
        reservedBottom: CGFloat
    ) -> CGRect {
        var usable = visibleFrame
        let floor = screenFrame.minY + reservedBottom
        if usable.minY < floor {
            usable.size.height -= floor - usable.minY
            usable.origin.y = floor
        }
        switch region {
        case .leftHalf:
            usable.size.width /= 2
        case .rightHalf:
            usable.size.width /= 2
            usable.origin.x += usable.width
        case .maximize:
            break
        }
        // AppKit measures from the bottom-left of the primary screen, the Accessibility API from its top-left.
        return CGRect(x: usable.minX, y: primaryScreenHeight - usable.maxY, width: usable.width, height: usable.height)
    }
}
