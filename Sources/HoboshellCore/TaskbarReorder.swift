import CoreGraphics

public enum TaskbarReorder {
    public static let dragThreshold: CGFloat = 6

    public static func anchor(draggedCenter: CGFloat, others: [(id: String, center: CGFloat)]) -> String? {
        others.first { $0.center > draggedCenter }?.id
    }
}
