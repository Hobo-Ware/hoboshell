import CoreGraphics

public enum TaskbarLayout {
    public static let iconOnlyWidth: CGFloat = 40
    public static let minLabelledWidth: CGFloat = 96
    public static let maxLabelledWidth: CGFloat = 170

    public static func buttonWidth(buttonCount: Int, availableWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        guard buttonCount > 0 else { return maxLabelledWidth }
        let share = (availableWidth - spacing * CGFloat(buttonCount - 1)) / CGFloat(buttonCount)
        if share >= maxLabelledWidth {
            return maxLabelledWidth
        }
        if share >= minLabelledWidth {
            return share.rounded(.down)
        }
        return iconOnlyWidth
    }

    public static func showsTitle(atWidth width: CGFloat) -> Bool {
        width >= minLabelledWidth
    }
}
