import CoreGraphics

public enum DockCalibration {
    public static let tileSizeRange = 16...128
    public static let startingOffset = 22

    public static func targetThickness(for edge: DockEdge) -> CGFloat {
        switch edge {
        case .bottom: return ShellLayout.taskbarHeight
        }
    }

    public static func startingTileSize(target: CGFloat) -> Int {
        clamp(Int(target.rounded()) - startingOffset)
    }

    public static func storageKey(for edge: DockEdge) -> String {
        "DockReserveTileSize.\(edge.rawValue)"
    }

    private static func clamp(_ size: Int) -> Int {
        min(max(size, tileSizeRange.lowerBound), tileSizeRange.upperBound)
    }
}
