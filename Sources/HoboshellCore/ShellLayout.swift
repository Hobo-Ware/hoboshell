import CoreGraphics

public struct ShellInsets: Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

public struct ShellLayout: Equatable {
    public static let taskbarHeight: CGFloat = 48
    public static let topBarHeight: CGFloat = 28
    public static let dockWidth: CGFloat = 64

    public let bar: CGRect
    public let dock: CGRect?
    public let reserved: ShellInsets
    public let dockReservation: DockReservation

    public init(
        variant: ShellVariant,
        screenFrame: CGRect,
        visibleFrame: CGRect,
        dockReservation: DockReservation = .off
    ) {
        self.dockReservation = dockReservation
        switch variant {
        case .bottomTaskbar:
            let height = dockReservation.thickness ?? Self.taskbarHeight
            bar = CGRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: height)
            dock = nil
            reserved = ShellInsets(bottom: height)
        case .topBarWithDock:
            let width = dockReservation.thickness ?? Self.dockWidth
            let topBar = CGRect(
                x: screenFrame.minX,
                y: visibleFrame.maxY - Self.topBarHeight,
                width: screenFrame.width,
                height: Self.topBarHeight
            )
            bar = topBar
            dock = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: width,
                height: topBar.minY - screenFrame.minY
            )
            reserved = ShellInsets(top: Self.topBarHeight, left: width)
        }
    }
}
