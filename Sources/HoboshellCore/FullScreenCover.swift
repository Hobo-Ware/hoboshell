import CoreGraphics

public enum FullScreenCover {
    public static func hidesBar(frontWindow: CGRect?, isFullScreen: Bool, barScreen: CGRect) -> Bool {
        guard isFullScreen, let frontWindow else { return false }
        return barScreen.contains(CGPoint(x: frontWindow.midX, y: frontWindow.midY))
    }
}
