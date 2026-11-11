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
        reserved: ShellInsets
    ) -> CGRect {
        let left = max(visibleFrame.minX, screenFrame.minX + reserved.left)
        let right = min(visibleFrame.maxX, screenFrame.maxX - reserved.right)
        let bottom = max(visibleFrame.minY, screenFrame.minY + reserved.bottom)
        let top = visibleFrame.maxY - reserved.top
        var usable = CGRect(x: left, y: bottom, width: right - left, height: top - bottom)
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
