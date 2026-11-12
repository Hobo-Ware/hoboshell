import CoreGraphics

public enum DockCalibration {
    public enum Step: Equatable {
        case done
        case adjust(tileSize: Int)
    }

    public static let tileSizeRange = 16...128
    public static let tolerance: CGFloat = 1
    public static let maxRounds = 3
    public static let startingOffset = 22

    public static func targetThickness(for edge: DockEdge) -> CGFloat {
        switch edge {
        case .bottom: return ShellLayout.taskbarHeight
        case .left: return ShellLayout.dockWidth
        }
    }

    public static func startingTileSize(target: CGFloat) -> Int {
        clamp(Int(target.rounded()) - startingOffset)
    }

    public static func storageKey(for edge: DockEdge) -> String {
        "DockReserveTileSize.\(edge.rawValue)"
    }

    public static func thickness(edge: DockEdge, frame: CGRect, visibleFrame: CGRect) -> CGFloat? {
        let measured: CGFloat
        switch edge {
        case .bottom: measured = visibleFrame.minY - frame.minY
        case .left: measured = visibleFrame.minX - frame.minX
        }
        return measured > 0 ? measured : nil
    }

    public static func next(measured: CGFloat, target: CGFloat, tileSize: Int) -> Step {
        let difference = target - measured
        guard abs(difference) > tolerance else { return .done }
        let adjusted = clamp(tileSize + Int(difference.rounded()))
        return adjusted == tileSize ? .done : .adjust(tileSize: adjusted)
    }

    private static func clamp(_ size: Int) -> Int {
        min(max(size, tileSizeRange.lowerBound), tileSizeRange.upperBound)
    }
}
